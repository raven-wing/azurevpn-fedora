#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Lightweight headless X + optional VNC for Azure VPN Client
# ---------------------------
#   • Starts Xvfb on :0 (resolution via $XVFB_WHD, default 1280x720x24)
#   • Launches minimal WM (fluxbox) to satisfy GTK/Flutter
#   • Optionally starts x11vnc if $VNC_PASSWORD is provided
#   • Keeps container alive with tail -f /dev/null

XVFB_WHD="${XVFB_WHD:-1280x720x24}"

# Start virtual framebuffer
echo "[entrypoint] starting Xvfb :0 ${XVFB_WHD}"
/usr/bin/Xvfb :0 -screen 0 ${XVFB_WHD} &
XVFB_PID=$!

# Allow Xvfb to initialize
sleep 2
export DISPLAY=:0

echo "[entrypoint] launching fluxbox WM"
fluxbox >/var/log/fluxbox.log 2>&1 &

# Optional VNC
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  echo "[entrypoint] VNC enabled on port 5900"
  mkdir -p /root/.vnc
  x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
  x11vnc -display :0 -forever -rfbauth /root/.vnc/passwd -rfbport 5900 &
else
  echo "[entrypoint] VNC disabled (set VNC_PASSWORD to enable)"
fi

# Wait indefinitely (container stays running)
wait ${XVFB_PID}
