#!/usr/bin/env bash
set -euo pipefail
set -x

make lint
if [ -f .circleci/config.yml ] && command -v circleci >/dev/null; then circleci config validate; fi
