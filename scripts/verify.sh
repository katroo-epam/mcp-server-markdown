#!/usr/bin/env bash
# verify.sh — run full verification pipeline
# Usage: bash scripts/verify.sh
# Exit code 0 = all checks passed, non-zero = something failed

set -e

echo "=== Installing dependencies ==="
pnpm install

echo "=== Typecheck ==="
pnpm typecheck

echo "=== Build ==="
pnpm build

echo "=== Tests ==="
pnpm test

echo "=== All checks passed ==="
