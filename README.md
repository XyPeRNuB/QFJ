# Clean Media Server Installer

A simple installer for a fresh Debian VPS.

## Installs

- qBittorrent 4.6.7 static
- FileBrowser
- Jellyfin
- BBR/fq network tuning

## Usage

Run this command as root:

```bash
bash <(curl -sL https://raw.githubusercontent.com/XyPeRNuB/QFJ/main/install.sh)
```
Default Ports
Service	URL
qBittorrent	http://YOUR_IP:8080
FileBrowser	http://YOUR_IP:808
Jellyfin	http://YOUR_IP:8096
Notes
Made for Debian-based VPS servers
Requires root access
No autobrr, no QUI, no mkbrr, no extra junk
qBittorrent downloads path: /home/USERNAME/qbittorrent/Downloads/
After Install

Reboot once for tuning: