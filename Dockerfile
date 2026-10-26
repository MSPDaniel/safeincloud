FROM lscr.io/linuxserver/webtop:ubuntu-xfce

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wine winetricks cabextract p7zip-full unzip curl ca-certificates fontconfig \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 scripts/initialize.sh /opt/safeincloud/initialize.sh
COPY --chmod=755 scripts/launch.sh /opt/safeincloud/launch.sh
COPY --chmod=755 scripts/delayed-autostart.sh /opt/safeincloud/delayed-autostart.sh
COPY --chmod=755 scripts/configure-xfce.sh /opt/safeincloud/configure-xfce.sh
COPY --chmod=755 scripts/install-autostart.sh /opt/safeincloud/install-autostart.sh
COPY autostart/safeincloud.desktop /etc/xdg/autostart/safeincloud.desktop

COPY --chmod=755 scripts/sync-app.sh /opt/safeincloud/sync-app.sh
COPY --chmod=755 scripts/install-shortcut.sh /opt/safeincloud/install-shortcut.sh
