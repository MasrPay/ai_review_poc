# 10-working-day POC plan

Start Thursday 15 Oct 2026. Assumes a Sunday–Thursday week and 1–2 hours/day.
Ends Wednesday 28 Oct 2026.

## Success criteria (decided before the first run)

| # | Criterion | Target | Hard gate? |
|---|---|---|---|
| S1 | Bad approvals (defect passed gate AND merge not blocked) | **0** | Yes — any failure stops the POC |
| S2 | Seeded defects caught by the gate (T02–T07, T09) | **7 / 7** | Yes |
| S3 | T08 (gate tampering) merge blocked by the ruleset | Blocked | Yes |
| S4 | Fail-closed tests F1–F10 behave as expected | **10 / 10** | Yes |
| S5 | Consistency: T02, T07, T09 × 3 runs each blocked | **9 / 9** | Yes |
| S6 | Valid PRs (T01, T10, Day-3 PR) pass the gate | **3 / 3** | Soft: 1 tuning round allowed |
| S7 | AI review finishes | p90 < 10 min | Soft |
| S8 | Usage | AI runs fit within your subscription limits; runs per PR recorded | Soft |

**Go** = all hard gates met. **Go with changes** = hard gates met, ≤ 2 soft
gates missed with a fix identified. **No-go** = any hard gate missed.

## Day by day

| Day | Date | Goal | Tasks | Done when |
|---|---|---|---|---|
| 1 | Thu 15 Oct | Tools and key | SETUP Steps 1–2: install, `claude doctor`, `specify version`, `claude setup-token` | All version commands print; token kept in password manager |
| 2 | Sun 18 Oct | Repo and protection | Steps 3–6: create repo, Spec Kit init, baseline, bootstrap, add a teammate as Write collaborator | Direct push rejected; ruleset active |
| 3 | Mon 19 Oct | First end-to-end PR | Step 7 with Spec Kit; confirm spec path pattern; read the AI comments critically | Gate result visible; inline comments posted |
| 4 | Tue 20 Oct | Seeds, part 1 | `seed-test-prs.sh … t01 t02 t03 t04 t05`; review every AI comment | 5 results recorded |
| 5 | Wed 21 Oct | Seeds, part 2 | `… t06 t07 t08 t09 t10`; first `poc-metrics.sh` | Metrics report v1 |
| 6 | Thu 22 Oct | Tune | Fix false positives/negatives by editing `SKILL.md` (via PR, teammate approves); consistency re-runs (S5) | S2, S5 measured |
| 7 | Sun 25 Oct | Fail-closed and hardening | Run F1–F10; confirm the Actions app ID pinned in the ruleset (SETUP "Known limits" #2) | S3, S4 measured |
| 8 | Mon 26 Oct | Team trial | 1–2 teammates each open one synthetic feature PR using Spec Kit; 10-minute feedback chat | Feedback noted; review times recorded |
| 9 | Tue 27 Oct | Integrations and reporting | Optional Teams webhook; CodeArts story-ID regex; ask Claude to turn `reports/poc-metrics.csv` into a dashboard | Notifications arrive; dashboard ready |
| 10 | Wed 28 Oct | Decision | Final metrics; usage notes; write the Go/No-go report (template below) | Report shared with your manager |

## Final report template

1. **Decision:** Go / Go with changes / No-go
2. **Results vs criteria:** S1–S8 table with actual values
3. **What the AI caught that CI didn't:** 2–3 concrete examples
4. **False positives and fixes applied**
5. **Cost:** number of AI runs and usage observed on the subscription; projected API cost for team rollout (estimate from a few API-key runs), projected monthly
   cost at the team's PR volume
6. **Risks and limits:** see SETUP "Known limits"
7. **Rollout proposal:** GitHub Team plan for private repos → one real repo
   in comment-only mode for 2 weeks → required gate after review → other
   repos. Security/IT sign-off before any real code is sent to the API.
