# Clean Media Server Installer

Installs:
- qBittorrent 4.6.7 (static)
- FileBrowser
- Jellyfin

## Usage

Run this command on your VPS:

```bash 
bash <(curl -sL https://raw.githubusercontent.com/XyPeRNuB/QFJ/main/install.sh)```bash
Services
qBittorrent → http://YOUR_IP:8080
FileBrowser → http://YOUR_IP:808
Jellyfin → http://YOUR_IP:8096
Notes
Requires root access
BBR network tuning is applied
Minimal setup (no autobrr, no extra tools)