# Installation & Setup

This guide explains how to install and configure the **Secure Backup Pipeline** on an Ubuntu 22.04 server.

---

## 1. System Requirements

- Ubuntu 22.04 LTS
- Python 3.10+
- Git, Bash, and `inotify-tools`
- ClamAV and ClamAV Daemon
- AWS CLI v2 (for S3 uploads)
- Prometheus, Grafana, and Loki (optional for monitoring)

---

## 2. Install Dependencies

Run the following commands to install the required packages:

```bash
sudo apt update
sudo apt install -y python3 python3-pip git unzip inotify-tools sysstat \
clamav clamav-daemon
