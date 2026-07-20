# Linux Monitoring Toolkit 🚀

> A dependency-free, production-grade Linux monitoring and alerting toolkit built with pure Bash scripting. Monitors CPU/memory/disk metrics, incrementally scans logs for errors using byte-offset tracking, checks systemd service health, and dispatches Slack/Email alerts—using only native Linux binaries (`bash`, `awk`, `sed`, `grep`, `systemctl`, `cron`).

---

## 📌 Overview

The **Linux Monitoring Toolkit** is a hands-on Linux system administration and DevOps project designed to explore how production Linux operating systems are observed, monitored, and troubleshooted under the hood without relying on heavy external third-party agents or languages.

Before deploying enterprise tools like Prometheus, Datadog, or Grafana, it is vital to understand how metrics, log streams, and service states are collected at the OS kernel and systemd level. This toolkit demonstrates those core fundamentals cleanly and reliably.

---

## ✨ Key Features & Technical Capabilities

* **📊 Real-time Resource Monitoring (`system_report.sh`)**:
  * Tracks CPU load average (1m/5m/15m) and core count via `/proc/loadavg`.
  * Monitors RAM/Swap consumption with configurable threshold alerts (`MEM_ALERT_THRESHOLD`).
  * Scans all mounted filesystems dynamically (`df -hT`) to catch full `/var` or `/data` partitions.
  * Captures Top 5 resource-consuming processes sorted by CPU and Memory utilization.

* **🔍 Incremental Log Error Scanning (`log_scan.sh`)**:
  * Scans log files and directories recursively for `ERROR`, `CRIT`, `FATAL`, `OOM`, and custom regex patterns.
  * **Byte-Offset State Tracking**: Remembers the exact byte offset scanned using state files (`logs/.offsets/`) so re-runs only inspect new log entries instead of re-alerting on historical errors.
  * **Log Rotation Guard**: Automatically resets offset pointers if log rotation occurs (file size shrinks).

* **⚙️ Service Health Checks (`service_health.sh`)**:
  * Checks systemd unit states using `systemctl is-active`.
  * **Explicit Exit Codes**: Returns `0` (All Up), `1` (One or more services down), or `2` (`systemctl` missing/container environment). Essential for downstream CI/CD pipelines or monitoring gates.

* **🚨 Robust Alerting Engine (`alert.sh`)**:
  * Multi-channel alerting via **Slack Webhooks** and **Email (`mailx`)**.
  * **Local-First Resilience**: All alerts are permanently written to `logs/alerts.log` first. A network failure or broken webhook never crashes the monitoring run.
  * Automatic JSON payload string escaping for special characters.

* **🔒 Concurrency Protection (`run_all.sh`)**:
  * Serves as the single master entry point for cron jobs.
  * Uses process lock files (`/tmp/linux-monitoring-toolkit.lock`) to prevent race conditions or overlapping execution cycles.

---

## 🛠️ Technologies Used

| Technology | Purpose |
| :--- | :--- |
| **Bash** | Primary automation & scripting language |
| **Linux / POSIX** | Target Operating System & environment |
| **systemd (`systemctl`)** | Service state management and health checking |
| **Cron** | Automated task scheduling & periodic execution |
| **awk / sed / grep** | High-performance text parsing and log filtering |
| **curl** | HTTP payload dispatching for Slack webhooks |
| **coreutils (`df`, `ps`, `free`)** | Native system resource data collection |

---

## 📂 Project Structure

```bash
linux-monitoring-toolkit/
├── config/
│   └── toolkit.conf        # Centralized configuration (services, log sources, thresholds, webhooks)
├── scripts/
│   ├── alert.sh            # Shared alerting library (Slack, Email, Local log)
│   ├── system_report.sh    # CPU, Memory, Disk, and Top Process snapshot script
│   ├── log_scan.sh         # Incremental log scanner with byte-offset tracking
│   ├── service_health.sh   # systemctl service checker with scriptable exit codes
│   └── run_all.sh          # Cron entry point with process lock guard
├── logs/
│   ├── monitor.log         # System report and check outputs log
│   ├── alerts.log          # Source of truth for all triggered alerts
│   └── .gitkeep
├── .gitignore              # Ignores runtime log artifacts and locks
└── README.md               # Project documentation
```

---

## ⚙️ Central Configuration (`config/toolkit.conf`)

All toolkit behavior is controlled from a single configuration file:

```bash
# --- Services to health-check ---
SERVICES_TO_CHECK=("ssh" "cron" "nginx" "docker")

# --- Log sources to scan ---
LOG_SOURCES=("/var/log/syslog" "/var/log/auth.log" "/var/log/nginx")
ERROR_PATTERN="ERROR|CRIT|CRITICAL|FATAL|FAILED|OOM"

# --- Resource Thresholds ---
DISK_ALERT_THRESHOLD=85     # Alert when any mount is >= 85% full
MEM_ALERT_THRESHOLD=90      # Alert when RAM usage is >= 90%

# --- Webhooks & Notifications ---
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
ALERT_EMAIL="admin@example.com"
```

---

## 🚀 Step-by-Step Procedure to Run Locally

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/sudarshanvashisht/linux-monitoring-toolkit.git
cd linux-monitoring-toolkit
```

### 2️⃣ Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### 3️⃣ Configure Toolkit Settings
Edit `config/toolkit.conf` to match your target system services and threshold preferences:
```bash
nano config/toolkit.conf
```

### 4️⃣ Run Scripts On-Demand

* **Generate a System Snapshot Report**:
  ```bash
  ./scripts/system_report.sh
  ```
  *(Outputs to terminal and appends to `logs/monitor.log`)*

* **Scan Logs for New Errors**:
  ```bash
  ./scripts/log_scan.sh
  ```

* **Check Monitored Systemd Services**:
  ```bash
  ./scripts/service_health.sh
  echo "Exit Code: $?"   # 0 = All Healthy | 1 = Service Down | 2 = systemctl N/A
  ```

* **Execute Complete Monitoring Pipeline**:
  ```bash
  ./scripts/run_all.sh
  ```

---

## ⏰ Automating with Cron (Periodic Monitoring)

To run the toolkit automatically every 5 minutes:

1. Open crontab editor:
   ```bash
   crontab -e
   ```

2. Add the following entry (adjusting path to your repository location):
   ```cron
   */5 * * * * /home/youruser/linux-monitoring-toolkit/scripts/run_all.sh >> /home/youruser/linux-monitoring-toolkit/logs/cron.log 2>&1
   ```

3. Verify cron execution:
   ```bash
   tail -f logs/monitor.log
   ```

---

## 📤 Step-by-Step Procedure to Push Updates to GitHub

If you make modifications or custom enhancements, push your updates using Git:

```bash
# 1. Check changed files
git status

# 2. Stage modified files
git add .

# 3. Commit your changes
git commit -m "Enhance monitoring toolkit logic and update documentation"

# 4. Set main branch
git branch -M main

# 5. Push to GitHub
git push -u origin main
```

---

## 💡 Skills Demonstrated & Engineering Focus

* **Production-Grade Resilience**: Avoiding hard failures using graceful fallbacks (`set -uo pipefail` over rigid `set -e`).
* **State Management in Bash**: Incremental state tracking using byte offsets.
* **DevOps Best Practices**: Decoupling configuration (`toolkit.conf`) from script execution logic.
* **Process Concurrency Guarding**: Atomic PID locking to prevent cron overlaps.
* **System Observability**: Deep understanding of `/proc`, `systemd`, `df`, `ps`, and Linux log formats.

---

## 🔮 Future Roadmap

* 🐳 Docker Container & Podman process health monitoring
* ☸️ Kubernetes Node & Kubelet metric collection
* 📈 Light-weight HTML report generation with chart visualization
* 🔒 Security audit monitoring (failed SSH login attempt tracking)

---

## 👤 Author

**SUDARSHAN VASHISHT**  
*Aspiring DevOps & Cloud Engineer*  
* GitHub: [@sudarshanvashisht](https://github.com/sudarshanvashisht)

---

⭐ **If you found this repository useful, feel free to give it a star on GitHub!**
