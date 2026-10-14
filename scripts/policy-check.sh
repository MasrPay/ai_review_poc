#!/usr/bin/env bash
# Deterministic PR policy checks. No network, no secrets.
# Inputs (env): BASE_SHA, HEAD_SHA, PR_TITLE, PR_BODY, STORY_ID_REGEX (optional)
#
# NOTE: this script runs from the PR's own checkout, so a PR can edit it.
# The real protection for this file is CODEOWNERS + "require code owner review".
set -euo pipefail

: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
PR_TITLE="${PR_TITLE:-}"
PR_BODY="${PR_BODY:-}"
STORY_ID_REGEX="${STORY_ID_REGEX:-}"

# Where Spec Kit puts feature specs. Adjust if your Spec Kit version differs.
SPEC_PATTERN='^specs/.+/spec\.md$'

# Files that must never be committed.
SENSITIVE_PATTERN='(^|/)(\.env(\..*)?|key\.properties|google-services\.json|GoogleService-Info\.plist|id_rsa|id_ed25519)$|\.(pem|p12|pfx|jks|keystore|key)$'
SENSITIVE_ALLOW='(^|/)\.env\.example$'

# Production code: anything that is not docs, specs or repo tooling.
NON_CODE_PATTERN='^(specs/|docs/|\.specify/|\.github/|\.claude/|scripts/)|(^|/)[^/]*\.md$|^\.gitignore$'

# Paths owned by the Team Lead (informational here; enforced by CODEOWNERS).
PROTECTED_PATTERN='^(\.github/|\.claude/|\.specify/memory/|scripts/)|^CLAUDE\.md$'

failures=()
notes=()

mapfile -t changed < <(git diff --name-only --diff-filter=ACMR "${BASE_SHA}...${HEAD_SHA}")
echo "Changed files (${#changed[@]}):"
printf '  %s\n' "${changed[@]:-<none>}"

# 1. Sensitive files
for f in "${changed[@]}"; do
  if [[ "$f" =~ $SENSITIVE_PATTERN ]] && ! [[ "$f" =~ $SENSITIVE_ALLOW ]]; then
    failures+=("Sensitive file must not be committed: $f")
  fi
done

# 2. Spec link for production code changes
code_changed=false
for f in "${changed[@]}"; do
  if ! [[ "$f" =~ $NON_CODE_PATTERN ]]; then code_changed=true; break; fi
done

if $code_changed; then
  spec_ok=false
  for f in "${changed[@]}"; do
    if [[ "$f" =~ $SPEC_PATTERN ]]; then spec_ok=true; notes+=("Spec changed in this PR: $f"); break; fi
  done
  if ! $spec_ok; then
    spec_line=$(printf '%s\n' "$PR_BODY" | tr -d '\r' | grep -E '^Spec:[[:space:]]*specs/' | head -n1 || true)
    spec_path=$(printf '%s' "$spec_line" | sed -E 's/^Spec:[[:space:]]*//; s/[[:space:]].*$//')
    if [[ -n "$spec_path" && "$spec_path" =~ $SPEC_PATTERN && -f "$spec_path" ]]; then
      spec_ok=true; notes+=("Spec referenced in PR body: $spec_path")
    fi
  fi
  $spec_ok || failures+=("Production code changed but no spec found. Add specs/<feature>/spec.md to the PR or a 'Spec: specs/<feature>/spec.md' line to the PR body.")
else
  notes+=("No production code changed; spec not required.")
fi

# 3. Protected paths (warning only)
for f in "${changed[@]}"; do
  if [[ "$f" =~ $PROTECTED_PATTERN ]]; then
    echo "::warning file=${f}::Protected path changed. Team Lead (code owner) approval is required to merge."
  fi
done

# 4. Story ID in title (only when configured)
if [[ -n "$STORY_ID_REGEX" ]]; then
  if [[ "$PR_TITLE" =~ $STORY_ID_REGEX ]]; then
    notes+=("Story ID found in title.")
  else
    failures+=("PR title must contain a story ID matching: $STORY_ID_REGEX")
  fi
fi

# Report
{
  echo "## Policy Checks"
  for n in "${notes[@]}"; do echo "- $n"; done
  if [ ${#failures[@]} -gt 0 ]; then
    echo "### Failures"
    for x in "${failures[@]}"; do echo "- $x"; done
  else
    echo "All policy checks passed."
  fi
} >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

if [ ${#failures[@]} -gt 0 ]; then
  for x in "${failures[@]}"; do echo "::error::$x"; done
  exit 1
fi
echo "Policy checks passed."
