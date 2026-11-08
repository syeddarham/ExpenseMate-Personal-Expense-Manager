#!/usr/bin/env bash
# Regression testing: runs the SAME system test suite (tests/system) against
#   1. the Assignment 01 baseline (git tag a01-baseline), and
#   2. the current working tree, started through `node server.js`,
# each on its own throwaway MySQL server. Results go to Assignment02/evidence/.
#
# Usage (from Backend/):  bash scripts/run-regression.sh [baseline-ref]
set -uo pipefail

REF="${1:-a01-baseline}"
BACKEND="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$BACKEND/.." && pwd)"
OUT="$REPO/Assignment02/evidence"
WORKTREE="$(mktemp -d -t expensemate-baseline-XXXXXX)"
mkdir -p "$OUT"

cleanup() { git -C "$REPO" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "== Checking out $REF into $WORKTREE"
git -C "$REPO" worktree add --detach "$WORKTREE" "$REF" >/dev/null
# The baseline commit still tracked a real .env; never let it be used.
rm -f "$WORKTREE/Backend/.env"
ln -s "$BACKEND/node_modules" "$WORKTREE/Backend/node_modules"

run() {
  local label="$1" target="$2" file="$3"
  echo "== System tests against $label"
  (cd "$BACKEND" && SYSTEM_TARGET="$target" node --test --test-reporter=spec tests/system/workflows.test.js) 2>&1 \
    | grep -vE '^\s+at ' | tee "$file" | grep -E '^(✔|✖)|^ℹ (tests|pass|fail)'
}

run "Assignment 01 baseline ($REF)" "$WORKTREE/Backend" "$OUT/regression-baseline.txt"
run "Assignment 02 (server.js)" "$BACKEND" "$OUT/regression-current.txt"
echo "== Full output saved in $OUT"
