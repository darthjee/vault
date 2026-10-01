#!/usr/bin/env bash
# Library: start, wait for and stop the inner Docker daemon.
# Sourcing this file only defines functions.

# Prints the hint shown when dockerd cannot run (missing privileges).
dockerd_privileges_hint() {
  echo "dockerd failed to start; are you running with --privileged (or the sysbox runtime)?"
}
