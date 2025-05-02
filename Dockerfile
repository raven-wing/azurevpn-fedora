FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget gnupg ca-certificates \
        xvfb x11vnc fluxbox \
        apt-transport-https && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor -o /usr/share/keyrings/ms_vpn.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ms_vpn.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-azurevpn.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends microsoft-azurevpnclient && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
