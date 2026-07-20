# Linux Monitoring Toolkit

> A lightweight, modular Linux monitoring and troubleshooting toolkit built with pure Bash scripting. Monitors CPU/memory/disk metrics, network statistics, systemd services, log files (using byte-offset tracking), Docker containers, and Kubernetes clusters — with multi-channel alerting and daily report generation.

---

## Overview

The **Linux Monitoring Toolkit** is a hands-on Linux system administration and DevOps project designed to observe, monitor, and troubleshoot production Linux operating systems without relying on heavy external third-party agents.

Before deploying cloud-native observability platforms like Prometheus, Grafana, or Datadog, understanding OS-level metrics, log streams, process trees, and network sockets is essential. This toolkit demonstrates core Linux administration, production-grade Bash scripting, and Site Reliability Engineering (SRE) concepts cleanly and reliably.

---

## Features & Capabilities

* **📊 CPU & Memory Monitoring**:
  * Tracks load averages (1m/5m/15m) and CPU core count.
  * Monitors RAM & Swap utilization with configurable alert thresholds.
  * Detects zombie processes.
  * Displays Top 3 resource-consuming processes sorted by CPU and Memory utilization.

* **💽 Smart Disk & Storage Analysis**:
  * Monitors mounted filesystems (`df -hT`).
  * **Zero False-Positives**: Automatically filters out pseudo-filesystems (`tmpfs`, `devtmpfs`, `overlay`) and read-only loop mounts (`/snap/*`, `squashfs`).

* **🌐 Network Statistics (`modules/network.sh`)**:
  * Detects primary IP address (`hostname -I` / `ip a`).
  * Lists active Listening Ports (`ss -tuln`).
  * Counts Established Connections (`ss -tun`).

* **⚙️ Intelligent Service Health Checks**:
  * Monitors systemd services (`ssh`, `cron`, `nginx`, `docker`, `containerd`, `kubelet`).
  * Differentiates between **NOT INSTALLED** services vs **INACTIVE** services to eliminate false critical alarms.
  * Gracefully handles non-systemd environments (WSL, minimal containers).

* **🔍 Incremental Log Error Scanning**:
  * Scans log files and directories (`/var/log/syslog`, `/var/log/nginx`, etc.) for `ERROR`, `CRIT`, `FATAL`, and `OOM` patterns.
  * **Byte-Offset State Tracking**: Remembers file offsets in `logs/.offsets/` so re-runs only inspect newly appended log entries instead of re-alerting on historical errors.
  * Resilient against log rotations.

* **🐳 Docker Container Monitoring**:
  * Checks Docker daemon availability.
  * Tracks total Running vs Stopped containers.
  * Displays a breakdown table of Container Names and States (`docker ps -a`).

* **☸️ Kubernetes Cluster Observability**:
  * Detects cluster environment (`k3s`, `Kind`, `Minikube`, or `Kubeadm`).
  * Reports Node readiness, Pod statuses (Running vs Failed/Pending), active Deployments, and Namespaces.

* **🛡️ Security Auditing**:
  * Scans authentication logs (`/var/log/auth.log` or `/var/log/secure`) for brute-force SSH failures and `sudo` authentication errors.

* **🚨 4-Tier Alerting Engine**:
  * Evaluates overall system state into 4 distinct severity tiers: `HEALTHY`, `WARNING`, `DEGRADED`, and `CRITICAL`.
  * Dispatches notifications via **Slack Webhooks**, **Email (`mailx`)**, and local log files (`logs/alerts.log`).

* **📄 Daily Report Generation & Log Rotation**:
  * Automatically saves timestamped daily summary reports in `reports/report_DD_MM_YYYY.txt`.
  * Automatically rotates and removes reports older than 7 days.

---

## Project Structure

```bash
linux-monitoring-toolkit/
├── config/
│   └── toolkit.conf        # Central configuration (services, thresholds, webhooks)
├── lib/
│   ├── alert.sh            # 4-tier alert routing engine (HEALTHY, WARNING, DEGRADED, CRITICAL)
│   ├── os_detect.sh        # OS, WSL, and systemd environment detection
│   └── utils.sh            # Terminal formatting and color utilities
├── modules/
│   ├── cpu_mem.sh          # CPU, Memory, Swap & Process monitoring
│   ├── disk.sh             # Storage & filesystem monitoring (filters /snap)
│   ├── docker.sh           # Docker daemon & container state monitoring
│   ├── kubernetes.sh       # K8s Node, Pod, Deployment & Namespace monitoring
│   ├── logs.sh             # Incremental log scanner with byte-offset tracking
│   ├── network.sh          # IP address, listening ports & established connections
│   ├── security.sh         # SSH & sudo authentication failure monitoring
│   └── services.sh         # systemd health checks (NOT INSTALLED vs INACTIVE)
├── scripts/
│   └── run_all.sh          # Master orchestrator script with PID locking
├── logs/                   # Log outputs and offset state files
└── reports/                # Auto-generated daily monitoring reports
```

---

## Getting Started

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/sudarshanvashisht/linux-monitoring-toolkit.git
cd linux-monitoring-toolkit
```

### 2️⃣ Make Scripts Executable
```bash
chmod +x scripts/*.sh lib/*.sh modules/*.sh
```

### 3️⃣ Configuration (Optional)
Edit `config/toolkit.conf` to customize monitored services, thresholds, or webhooks:
```bash
nano config/toolkit.conf
```

### 4️⃣ Run the Monitoring Pipeline
```bash
./scripts/run_all.sh
```

---

## Automating with Cron

To run the toolkit automatically every 5 minutes and append to daily reports:

```bash
crontab -e
```

Add the following crontab entry (adjust path to your installation directory):
```cron
*/5 * * * * /home/youruser/linux-monitoring-toolkit/scripts/run_all.sh --quiet >> /home/youruser/linux-monitoring-toolkit/logs/cron.log 2>&1
```

---

## DevOps & SRE Perspective

Monitoring is a core responsibility for DevOps Engineers, Site Reliability Engineers (SREs), and Linux Administrators. This project focuses on understanding system telemetry from the Linux OS kernel level before introducing complex cloud-native tools like Prometheus, Grafana, or Datadog.

---

**Author: sudarshanvashisht**  
*Aspiring DevOps & Cloud Engineer*

⭐ **If you found this project helpful, feel free to give it a star on GitHub!**
