#!/usr/bin/env bash
set -euo pipefail
set -x

make lint
if command -v circleci >/dev/null; then circleci config validate; fi
