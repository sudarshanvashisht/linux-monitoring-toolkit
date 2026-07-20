# Contributing to Linux Monitoring Toolkit

First off, thank you for considering contributing to this project! It's people like you that make the open-source community such a great place to learn, inspire, and create.

## How Can I Contribute?

### Reporting Bugs
- Ensure the bug was not already reported by searching on GitHub under Issues.
- If you're unable to find an open issue addressing the problem, open a new one. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

### Suggesting Enhancements
- Open a new issue with the label `enhancement`.
- Provide a clear and detailed explanation of the feature you want and why it's important.

### Pull Requests
1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure your code lints properly (we use ShellCheck for Bash scripts).
5. Issue that pull request!

## Code Style
- Follow standard Bash conventions.
- Use `set -uo pipefail` in all scripts.
- Document any complex logic.
- Ensure cross-compatibility (where possible) across major Linux distributions (Ubuntu, Debian, RHEL, CentOS).
