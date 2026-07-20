# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-07-20

### Added
- **Major Architectural Overhaul**: Transitioned from standalone scripts to a modular library-based architecture.
- **Docker Monitoring**: Added `modules/docker.sh` for tracking container and daemon states.
- **Kubernetes Monitoring**: Added `modules/kubernetes.sh` for observing Node and Pod availability.
- **Security Auditing**: Added `modules/security.sh` to track failed SSH and `sudo` privilege escalation attempts.
- **Enhanced Alerting Engine**: Tri-state severity model (`HEALTHY`, `WARNING`, `CRITICAL`) replacing binary pass/fail checks.

### Changed
- Refactored `system_report.sh` into decoupled `cpu_mem.sh` and `disk.sh` modules.
- Refactored disk monitoring to strictly ignore pseudo-filesystems and snap loop devices (`squashfs`).
- Rebuilt `run_all.sh` to dynamically source components and provide a colorized terminal dashboard.
- Upgraded configuration file (`toolkit.conf`) to support module toggling and granular thresholds.

### Removed
- Removed monolithic legacy scripts (`alert.sh`, `system_report.sh`, `log_scan.sh`, `service_health.sh`) from `scripts/` directory.

## [1.0.0] - Initial Release
- Initial basic monitoring scripts (CPU, Memory, Disk, Services, Logs).
- Slack webhook and Email alerting support.
