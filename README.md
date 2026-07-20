# Linux Monitoring Toolkit

> A lightweight Linux monitoring and troubleshooting toolkit built with Bash scripting to monitor system resources, inspect processes, analyze logs, and understand how Linux systems are operated in real-world DevOps environments.

## Overview

The Linux Monitoring Toolkit is one of my hands-on Linux projects built while learning Linux Administration, Shell Scripting, and DevOps fundamentals.

The primary goal of this project is not only to monitor system resources but also to understand how production Linux systems are observed and troubleshooted. It focuses on the fundamentals that every Linux Administrator, DevOps Engineer, and Cloud Engineer should know.

This project helped me explore:
* Linux System Monitoring & Bash Shell Scripting
* CPU, Memory and Disk Analysis
* Linux Logging and Troubleshooting
* Automation (Cron) & Service Management (systemd)
* Optional Docker and Kubernetes observation

---

## Features

* **CPU & Memory Monitoring**: Track load averages, RAM/Swap usage, and top resource-consuming processes.
* **Disk Monitoring**: Check disk statistics while smartly ignoring pseudo-filesystems (like `/snap` or `/proc`).
* **Service Health Checks**: Monitor systemd services (nginx, ssh, docker) with graceful fallbacks.
* **Log Analysis**: Incrementally scan logs for errors (using byte-offset tracking to prevent duplicate alerts).
* **Security & Container Audits**: Audit failed SSH/sudo attempts and optionally monitor Docker and Kubernetes nodes/pods.
* **Alerting**: Tri-state severity levels (HEALTHY, WARNING, CRITICAL) with local logging, Email, and Slack webhook support.

---

## Project Structure

```bash
linux-monitoring-toolkit/
├── config/
│   └── toolkit.conf        # Central configuration (services, thresholds, webhooks)
├── lib/
│   ├── alert.sh            # Alert routing engine
│   ├── os_detect.sh        # OS and systemd detection
│   └── utils.sh            # Colors and formatting
├── modules/
│   ├── cpu_mem.sh          # CPU & Memory monitoring
│   ├── disk.sh             # Storage & Filesystem monitoring
│   ├── docker.sh           # Docker monitoring
│   ├── kubernetes.sh       # K8s Node & Pod monitoring
│   ├── logs.sh             # Log scanning
│   ├── security.sh         # Security audit monitoring
│   └── services.sh         # systemd health checks
├── scripts/
│   └── run_all.sh          # Main execution orchestrator
└── logs/                   # Generated reports and offset files
```

---

## Getting Started

**1. Clone the repository:**
```bash
git clone https://github.com/sudarshanvashisht/linux-monitoring-toolkit.git
cd linux-monitoring-toolkit
```

**2. Make scripts executable:**
```bash
chmod +x scripts/*.sh lib/*.sh modules/*.sh
```

**3. Configure your settings (optional):**
```bash
nano config/toolkit.conf
```

**4. Run the monitoring dashboard:**
```bash
./scripts/run_all.sh
```

---

## Automating with Cron

To run the toolkit automatically every 5 minutes, add this to your crontab (`crontab -e`):

```cron
*/5 * * * * /home/youruser/linux-monitoring-toolkit/scripts/run_all.sh --quiet >> /home/youruser/linux-monitoring-toolkit/logs/cron.log 2>&1
```

---

## DevOps Perspective

Monitoring is one of the fundamental responsibilities of Site Reliability Engineers (SREs), DevOps Engineers, and System Administrators. This project focuses on understanding monitoring from the Linux operating system itself before moving towards heavy cloud-native solutions like Prometheus and Grafana.

---

I enjoy building hands-on projects that strengthen my understanding of Linux internals, automation, and infrastructure.

**Author: sudarshanvashisht**

⭐ **If you found this project useful, feel free to give it a star on GitHub!**
