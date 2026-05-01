#!/bin/bash
set -e

echo "==== Clean Media Server (qBittorrent 4.6.7) ===="

PUBLIC_IP=$(curl -4 -s ifconfig.me)

read -p "Username: " USERNAME
read -s -p "Password (min 12 chars): " PASSWORD
echo ""

read -p "qBittorrent WebUI port [8080]: " QBIT_PORT
QBIT_PORT=${QBIT_PORT:-8080}

read -p "Incoming port [45000]: " IN_PORT
IN_PORT=${IN_PORT:-45000}

read -p "FileBrowser port [808]: " FB_PORT
FB_PORT=${FB_PORT:-808}

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  QBT_ARCH="aarch64"
elif [ "$ARCH" = "x86_64" ]; then
  QBT_ARCH="x86_64"
else
  echo "Unsupported arch"
  exit 1
fi

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing base packages..."
apt install -y curl wget ufw ffmpeg mediainfo ca-certificates gnupg

echo "Adding Jellyfin repo..."
mkdir -p /usr/share/keyrings
curl -fsSL https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg

echo "deb [signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/debian bookworm main" > /etc/apt/sources.list.d/jellyfin.list

apt update
apt install -y jellyfin

echo "Creating user..."
useradd -m -s /bin/bash "$USERNAME" 2>/dev/null || true
echo "$USERNAME:$PASSWORD" | chpasswd

mkdir -p /home/$USERNAME/qbittorrent/Downloads
mkdir -p /home/$USERNAME/.config/qBittorrent
chown -R $USERNAME:$USERNAME /home/$USERNAME

echo "Installing qBittorrent 4.6.7 static..."
wget -O /usr/local/bin/qbittorrent-nox \
https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.6.7_v2.0.10/${QBT_ARCH}-qbittorrent-nox

chmod +x /usr/local/bin/qbittorrent-nox

echo "Generating qBittorrent config..."
cat > /home/$USERNAME/.config/qBittorrent/qBittorrent.conf <<EOF
[Preferences]
WebUI\\Port=$QBIT_PORT
WebUI\\Username=$USERNAME

[BitTorrent]
Session\\Port=$IN_PORT
Session\\DefaultSavePath=/home/$USERNAME/qbittorrent/Downloads/
Session\\DiskCacheSize=2048
Session\\AsyncIOThreadsCount=8
EOF

chown -R $USERNAME:$USERNAME /home/$USERNAME

echo "Creating qBittorrent service..."
cat > /etc/systemd/system/qbittorrent-nox@$USERNAME.service <<EOF
[Unit]
Description=qBittorrent
After=network.target

[Service]
User=$USERNAME
ExecStart=/usr/local/bin/qbittorrent-nox --webui-port=$QBIT_PORT
Restart=always
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl enable qbittorrent-nox@$USERNAME

echo "Installing FileBrowser..."
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

echo "Configuring FileBrowser..."
filebrowser config init
filebrowser config set --port $FB_PORT --root /home/$USERNAME

FB_PASS="$PASSWORD"
if [ ${#FB_PASS} -lt 12 ]; then
  FB_PASS="${PASSWORD}1234"
fi

filebrowser users add $USERNAME $FB_PASS --perm.admin

cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=FileBrowser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable filebrowser

echo "Applying BBR tuning..."
cat > /etc/sysctl.d/99-tuning.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl --system

echo "Firewall..."
ufw allow OpenSSH
ufw allow $QBIT_PORT
ufw allow $IN_PORT
ufw allow $FB_PORT
ufw allow 8096
ufw --force enable

echo "Starting services..."
systemctl daemon-reload
systemctl restart qbittorrent-nox@$USERNAME
systemctl restart filebrowser
systemctl enable jellyfin
systemctl restart jellyfin

echo ""
echo "===== DONE ====="
echo "qBittorrent: http://$PUBLIC_IP:$QBIT_PORT"
echo "FileBrowser: http://$PUBLIC_IP:$FB_PORT"
echo "Jellyfin: http://$PUBLIC_IP:8096"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"