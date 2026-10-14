#!/usr/bin/env bash
# Scores the seeded PRs: expected outcome (seed:* label) vs gate result (ai-gate:* label).
# Writes reports/poc-metrics.md and reports/poc-metrics.csv.
# Usage: scripts/poc-metrics.sh <owner>/<repo>
set -euo pipefail

REPO="${1:?Usage: scripts/poc-metrics.sh <owner>/<repo>}"
ROOT="$(git rev-parse --show-toplevel)"
mkdir -p "$ROOT/reports"
MD="$ROOT/reports/poc-metrics.md"
CSV="$ROOT/reports/poc-metrics.csv"

data=$(gh pr list --repo "$REPO" --state all --limit 200 \
  --search 'label:"seed:expect-pass","seed:expect-block"' \
  --json number,title,url,labels,reviewDecision,mergeStateStatus,state)

rows=$(echo "$data" | jq -r '
  def has(l): any(.labels[]; .name == l);
  .[] | {
    n: .number, t: .title, u: .url, state: .state,
    expect: (if has("seed:expect-pass") then "pass" else "block" end),
    gate:   (if has("ai-gate:pass") then "pass" elif has("ai-gate:fail") then "fail" else "pending" end),
    merge: (.mergeStateStatus // "UNKNOWN"),
    review: (.reviewDecision // "NONE")
  }
  | .outcome = (
      if .gate == "pending" then "PENDING"
      elif .expect == "block" and .gate == "fail" then "CAUGHT"
      elif .expect == "block" and .gate == "pass" then (if .state == "MERGED" then "BAD APPROVAL" elif .merge == "BLOCKED" then "GATE MISSED, MERGE BLOCKED" else "GATE MISSED" end)
      elif .expect == "pass" and .gate == "pass" then "CORRECT PASS"
      else "FALSE POSITIVE" end)
  | [.n, .t, .expect, .gate, .merge, .review, .outcome, .u] | @tsv')

{
  echo "number,title,expected,gate,merge_state,review_decision,outcome,url"
  echo "$rows" | awk -F'\t' 'NF { gsub(/"/, "\"\"", $2); printf "%s,\"%s\",%s,%s,%s,%s,%s,%s\n", $1,$2,$3,$4,$5,$6,$7,$8 }'
} > "$CSV"

count() { echo "$rows" | awk -F'\t' -v o="$1" 'NF && $7 == o' | wc -l | tr -d ' '; }
blocks=$(echo "$rows" | awk -F'\t' 'NF && $3 == "block"' | wc -l | tr -d ' ')
passes=$(echo "$rows" | awk -F'\t' 'NF && $3 == "pass"' | wc -l | tr -d ' ')
caught=$(count "CAUGHT")
bad=$(count "BAD APPROVAL")
gate_missed=$(count "GATE MISSED, MERGE BLOCKED")
correct=$(count "CORRECT PASS")
fp=$(count "FALSE POSITIVE")
pending=$(count "PENDING")

{
  echo "# POC metrics — $(date -u +%Y-%m-%dT%H:%MZ)"
  echo
  echo "| Metric | Value | Target |"
  echo "|---|---|---|"
  echo "| Seeded defects caught by the gate | $caught / $blocks | ≥ 90% |"
  echo "| Bad approvals (defect passed gate AND merge not blocked) | $bad | 0 |"
  echo "| Gate missed but ruleset blocked merge | $gate_missed | T08 only |"
  echo "| Gate missed, merge NOT blocked (open PR) | $(count "GATE MISSED") | 0 |"
  echo "| Valid PRs passed | $correct / $passes | 100% |"
  echo "| False positives (valid PR failed gate) | $fp | ≤ 1 |"
  echo "| Pending | $pending | 0 |"
  echo
  echo "| PR | Title | Expected | Gate | Merge state | Outcome |"
  echo "|---|---|---|---|---|---|"
  echo "$rows" | awk -F'\t' 'NF { printf "| [#%s](%s) | %s | %s | %s | %s | %s |\n", $1,$8,$2,$3,$4,$5,$7 }'
  echo
  echo "Usage: runs on the Team Lead's Claude subscription during the POC; record AI Review run count and duration (Actions tab)."
} > "$MD"

cat "$MD"
echo
echo "Wrote $MD and $CSV"
