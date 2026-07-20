# Linux Monitoring Toolkit

A dependency-free Bash toolkit that reports CPU/memory/disk usage, scans logs
for errors, and checks service health — with Slack/email alerting — using
nothing but core Linux tools (`bash`, `awk`, `sed`, `grep`, `systemctl`,
`cron`). No agent, no Python, no third-party binary required.

## Why this exists

Most "monitoring" a fresher can point to is "I installed Datadog/New Relic."
This proves you understand what those agents are actually doing under the
hood — and it works on any box, including ones you're not allowed to install
third-party software on.

## Project structure

```
linux-monitoring-toolkit/
├── config/
│   └── toolkit.conf        # single place to configure services, thresholds, webhook
├── scripts/
│   ├── alert.sh             # shared alerting library (sourced, not run directly)
│   ├── system_report.sh     # CPU / memory / disk / top processes
│   ├── log_scan.sh          # scans logs for ERROR/CRIT patterns (incremental)
│   ├── service_health.sh    # systemctl health check, real exit codes
│   └── run_all.sh           # single entry point — this is what cron calls
├── logs/
│   ├── monitor.log          # all report output, appended over time
│   └── alerts.log           # every alert ever fired, local source of truth
└── README.md
```

## Setup

```bash
git clone <your-repo-url> linux-monitoring-toolkit
cd linux-monitoring-toolkit
chmod +x scripts/*.sh

# Edit config/toolkit.conf:
#   - SERVICES_TO_CHECK: real systemd unit names on your box (`systemctl list-units --type=service`)
#   - LOG_SOURCES: real log paths on your box
#   - SLACK_WEBHOOK_URL: your Slack incoming webhook, if you want alerts (optional)
#   - DISK_ALERT_THRESHOLD / MEM_ALERT_THRESHOLD: tune to taste
vim config/toolkit.conf
```

## Running it on demand

```bash
./scripts/system_report.sh          # prints to terminal AND logs/monitor.log
./scripts/log_scan.sh                # scans for new errors since last run
./scripts/service_health.sh; echo $? # 0 = all up, 1 = something down, 2 = couldn't check
./scripts/run_all.sh                 # everything in one shot — what cron will call
```

### Example output — `system_report.sh`

```
==================== SYSTEM REPORT: 2026-07-19 09:05:01 ====================
CPU: load avg (1/5/15m) = 0.42 / 0.38 / 0.31  (cores: 4)
MEMORY: used=1820MB total=3936MB (46.2%)
DISK USAGE:
  /: 12G/40G used (31%)
  /var: 8.1G/20G used (42%)
TOP 5 PROCESSES BY CPU:
  USER       PID    %CPU   %MEM   COMMAND
  www-data   1421   12.3   4.1    gunicorn
  postgres   998    5.7    8.2    postgres
  ...
TOP 5 PROCESSES BY MEMORY:
  ...
================================================================
```

### Example output — `service_health.sh` (with a service down)

```
$ ./scripts/service_health.sh; echo "exit code: $?"
One or more services are down. See logs/monitor.log.
exit code: 1
```

And in `logs/monitor.log`:
```
==================== SERVICE HEALTH: 2026-07-19 09:05:02 ====================
  [OK]   ssh: active
  [OK]   cron: active
  [DOWN] nginx: failed
  [OK]   docker: active
===================================================================
```

## Wiring into cron (every 5 minutes)

```bash
crontab -e
```

Add this line (adjust the path):

```cron
*/5 * * * * /home/youruser/linux-monitoring-toolkit/scripts/run_all.sh >> /home/youruser/linux-monitoring-toolkit/logs/cron.log 2>&1
```

Verify cron is actually picking it up:

```bash
grep CRON /var/log/syslog | tail    # Debian/Ubuntu
journalctl -u cron --since '10 min ago'
```

## Alerting

`alert.sh` always writes to `logs/alerts.log` first, regardless of whether
Slack/email are configured — that's a deliberate design choice: **the local
log must never depend on an external service being reachable.** Slack and
email are best-effort on top of that.

To enable Slack: create an
[Incoming Webhook](https://api.slack.com/messaging/webhooks) in your
workspace and paste the URL into `SLACK_WEBHOOK_URL` in `config/toolkit.conf`.

## Edge cases this toolkit deliberately handles

| Edge case | How it's handled |
|---|---|
| Log file gets rotated between runs (size shrinks) | `log_scan.sh` compares current file size to the last saved offset; if it shrank, resets to offset 0 instead of erroring or hanging. |
| Re-running every 5 minutes shouldn't re-report the same old errors forever | `log_scan.sh` tracks a byte-offset per file under `logs/.offsets/` and only scans bytes appended since the last run. |
| `systemctl` doesn't exist (e.g. running inside a minimal Docker container) | `service_health.sh` detects this and exits with a distinct code (`2`) meaning "couldn't check," not "checked and found down" — an important distinction for anything consuming the exit code. |
| Slack webhook is down or misconfigured | `alert.sh` catches the `curl` failure, logs a warning locally, and does **not** crash the calling script — a broken webhook should never take down monitoring itself. |
| A single metric fails to collect (e.g. `free` not installed on a stripped-down image) | Each check in `system_report.sh` is independently guarded; one missing tool logs "skipping" for that metric only, the rest of the report still runs (`set -e` is deliberately NOT used here for this reason). |
| Two cron-triggered runs overlap because one run took longer than 5 minutes | `run_all.sh` uses a PID lock file (`/tmp/linux-monitoring-toolkit.lock`) and skips the new run if the previous one is still alive. |
| Disk check only looking at `/` and missing a full `/var` or `/data` | `system_report.sh` loops over **every** real mounted filesystem from `df`, not just root. |
| Alert message contains characters that break the Slack JSON payload | `alert.sh` escapes double quotes before building the JSON body. |

## What to say about this project in an interview

- Walk through the offset-tracking logic in `log_scan.sh` — it's the single
  most "senior" detail in this project and interviewers notice it.
- Be ready to explain why `set -e` is intentionally *not* used in
  `system_report.sh` but arguably could be used elsewhere — trade-offs, not
  dogma.
- Be ready to explain the difference between exit codes `0`, `1`, and `2` in
  `service_health.sh` and why that distinction matters for anything
  downstream consuming this script (cron, CI, another monitoring layer).
