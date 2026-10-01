#!/usr/bin/env bash
set -euo pipefail
set -x

make lint
make test
make test-image
