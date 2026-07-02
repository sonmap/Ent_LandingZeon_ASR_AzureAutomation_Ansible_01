#!/usr/bin/env bash
set -euo pipefail

required_paths=(
  "primary-krc"
  "dr-jpe"
  "asr"
  "runbooks/azure-automation"
  "ansible/playbooks"
  "docs"
)

for p in "${required_paths[@]}"; do
  if [[ ! -e "$p" ]]; then
    echo "Missing: $p"
    exit 1
  fi
  echo "OK: $p"
done

echo "Repository layout validation completed."
