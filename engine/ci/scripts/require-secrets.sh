#!/usr/bin/env bash
# Fail loudly when required environment variables are empty.
# Usage: require-secrets.sh NAME [NAME...]   (reads the variables from the environment)
# Prints the NAMES that are missing, never values. Exit 1 if any are missing.
set -u
missing=()
for name in "$@"; do
  if [ -z "${!name:-}" ]; then missing+=("$name"); fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  for name in "${missing[@]}"; do
    echo "::error::Required secret $name is not set. Add it under Settings > Secrets and variables > Actions."
  done
  echo "Refusing to continue: a guard that cannot run is a failed guard, not a passed one." >&2
  exit 1
fi
echo "All required secrets are present: $*"
