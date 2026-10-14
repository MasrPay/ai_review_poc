#!/usr/bin/env bash
# One-time hardening of the POC repository. Idempotent: safe to re-run.
# Usage: scripts/bootstrap-repo.sh <owner>/<repo>
# Requires: gh (authenticated as a repo admin / org owner), jq, git.
# Works with macOS bash 3.2.
set -euo pipefail

REPO="${1:?Usage: scripts/bootstrap-repo.sh <owner>/<repo>}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

say()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

for cmd in gh jq git; do
  command -v "$cmd" >/dev/null || { echo "Missing required tool: $cmd" >&2; exit 1; }
done
gh auth status >/dev/null 2>&1 || { echo "Run: gh auth login" >&2; exit 1; }

visibility=$(gh repo view "$REPO" --json visibility --jq .visibility)
say "Repository: $REPO ($visibility)"
if [ "$visibility" != "PUBLIC" ]; then
  warn "Repo is not public. On GitHub Free, rulesets are NOT enforced on private repos."
fi

# ---------------------------------------------------------------- CODEOWNERS
LEAD="$(gh api user --jq .login)"
say "Setting CODEOWNERS owner to @$LEAD"
if grep -q '@TEAM_LEAD' .github/CODEOWNERS; then
  [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "Check out main first." >&2; exit 1; }
  sed -i.bak "s/@TEAM_LEAD/@${LEAD}/g" .github/CODEOWNERS && rm -f .github/CODEOWNERS.bak
  git add .github/CODEOWNERS
  git commit -q -m "chore: set code owner to @${LEAD}"
  git push -q origin main
  echo "CODEOWNERS committed and pushed to main."
fi

# ---------------------------------------------------- Actions: least privilege
say "Restricting GitHub Actions"
# Only GitHub-owned actions plus the two we pin by SHA.
gh api -X PUT "repos/$REPO/actions/permissions" \
  -F enabled=true -f allowed_actions=selected >/dev/null
gh api -X PUT "repos/$REPO/actions/permissions/selected-actions" --input - >/dev/null <<'JSON'
{
  "github_owned_allowed": true,
  "verified_allowed": false,
  "patterns_allowed": ["anthropics/claude-code-action@*", "dart-lang/setup-dart@*"]
}
JSON
# Default GITHUB_TOKEN is read-only, and workflows may NOT approve PRs.
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false >/dev/null
# Fork PRs from anyone outside the repo need manual approval before running.
gh api -X PUT "repos/$REPO/actions/permissions/fork-pr-contributor-approval" \
  -f approval_policy=all_external_contributors >/dev/null \
  || warn "Could not set fork PR approval policy; set it in Settings > Actions > General."

# ----------------------------------------------------------- repo settings
say "Repository merge settings"
gh repo edit "$REPO" --enable-auto-merge=false --delete-branch-on-merge >/dev/null

say "Secret scanning + push protection (free on public repos)"
gh api -X PATCH "repos/$REPO" --input - >/dev/null <<'JSON' || warn "Could not enable secret scanning; enable it in Settings > Code security."
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
JSON

# ------------------------------------------------------------------ labels
say "Labels"
gh label create "ai-gate:pass"       --repo "$REPO" --color 2DA44E --description "AI Review Gate passed" --force
gh label create "ai-gate:fail"       --repo "$REPO" --color CF222E --description "AI Review Gate failed" --force
gh label create "seed:expect-pass"   --repo "$REPO" --color 0969DA --description "POC test PR expected to pass" --force
gh label create "seed:expect-block"  --repo "$REPO" --color 8250DF --description "POC test PR expected to be blocked" --force

# ------------------------------------------------------------------ secret
say "Claude subscription token"
if gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -qx CLAUDE_CODE_OAUTH_TOKEN; then
  echo "CLAUDE_CODE_OAUTH_TOKEN already set (not shown)."
else
  echo "Paste the token from 'claude setup-token' when prompted. It is sent to GitHub encrypted and never echoed."
  gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo "$REPO"
fi

# ------------------------------------------------------------ develop branch
say "develop branch"
if gh api "repos/$REPO/git/ref/heads/develop" >/dev/null 2>&1; then
  echo "develop exists."
else
  main_sha=$(gh api "repos/$REPO/git/ref/heads/main" --jq .object.sha)
  gh api "repos/$REPO/git/refs" -f ref=refs/heads/develop -f sha="$main_sha" >/dev/null
  echo "develop created from main ($main_sha)."
fi
if gh api -H "Accept: application/vnd.github.raw" \
     "repos/$REPO/contents/.github/CODEOWNERS?ref=develop" 2>/dev/null | grep -q '@TEAM_LEAD'; then
  warn "develop still has the @TEAM_LEAD placeholder in CODEOWNERS; code-owner review won't apply there."
  warn "Fix before the ruleset exists: gh api -X PATCH repos/$REPO/git/refs/heads/develop -f sha=\$(git rev-parse main) -F force=true"
fi

# ------------------------------------------------------------------ ruleset
say "Ruleset (protect main and develop)"
existing=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="protect-main-develop") | .id' || true)
if [ -n "$existing" ]; then
  gh api -X PUT "repos/$REPO/rulesets/$existing" --input .github/rulesets/protect-main-develop.json >/dev/null
  echo "Ruleset updated (id $existing)."
else
  gh api -X POST "repos/$REPO/rulesets" --input .github/rulesets/protect-main-develop.json >/dev/null
  echo "Ruleset created."
fi

say "Done. Next: docs/SETUP.md step 6 (verify the protection)."
