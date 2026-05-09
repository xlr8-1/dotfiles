#!/bin/bash

set -euo pipefail

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require chezmoi

chezmoi data >/dev/null
chezmoi apply --dry-run >/dev/null
