#!/usr/bin/env bash
set -euo pipefail

################################################################################
# entrypoint.sh — headless Xvfb (+ optional VNC) launcher for Azure VPN Client #
################################################################################
# Tunable environment variables:
#   DISPLAY_NUM   — display number (default 0). If busy, script bumps to next.
#   XVFB_WHD      — geometry WxHxDepth (default 1280x720x24)
#   VNC_PASSWORD  — if set, starts x11vnc on port 5900 with this password.
#                   leave unset to disable VNC entirely.
# -----------------------------------------------------------------------------

# ---------- config ----------
DISPLAY_NUM="${DISPLAY_NUM:-0}"
XVFB_WHD="${XVFB_WHD:-1280x720x24}"

# ---------- helpers ----------
cleanup_socket() {
  local disp="$1"
  rm -f "/tmp/.X${disp}-lock" "/tmp/.X11-unix/X${disp}" || true
}

start_xvfb() {
  local disp="$1"
  echo "[entrypoint] starting Xvfb :${disp} ${XVFB_WHD}"
  Xvfb ":${disp}" -screen 0 "${XVFB_WHD}" -nolisten tcp &
  pid=$!
  sleep 1
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "[entrypoint] Xvfb failed on :${disp}"
    return 1
  fi
  echo "[entrypoint] Xvfb started on DISPLAY=:${disp}"
  export DISPLAY=":${disp}"
  return 0
}

# ---------- main ----------
max_tries=10
tries=0
while (( tries < max_tries )); do
  cleanup_socket "$DISPLAY_NUM"
  if start_xvfb "$DISPLAY_NUM"; then
    break
  fi
  echo "[entrypoint] DISPLAY :$DISPLAY_NUM busy; trying next"
  DISPLAY_NUM=$((DISPLAY_NUM+1))
  ((tries++))
  sleep 1
done

if (( tries == max_tries )); then
  echo "[entrypoint] ERROR: could not start Xvfb after ${max_tries} attempts" >&2
  exit 1
fi

# start lightweight WM so GTK/Flutter are happy
fluxbox &

# Optional VNC
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  echo "[entrypoint] enabling x11vnc on :5900"
  # generate password file
  mkdir -p /tmp/.vnc
  echo "$VNC_PASSWORD" | vncpasswd -f > /tmp/.vnc/passwd
  chmod 600 /tmp/.vnc/passwd
  x11vnc -rfbauth /tmp/.vnc/passwd -forever -shared -nopw -display "$DISPLAY" -rfbport 5900 -logfile /tmp/x11vnc.log &
else
  echo "[entrypoint] VNC disabled (set VNC_PASSWORD to enable)"
fi

# keep container running
exec tail -f /dev/null
