# Engineering Constitution

> Non-negotiable principles for every spec, plan, task and line of code.
> Stack-agnostic: applies to mobile, backend, web and DevOps work.
> Version 1.0 · Owner: Engineering Team Lead · Changes need Team Lead approval (CODEOWNERS).

## I. Security first (FinTech)

Security requirements override delivery speed. A plan that weakens security is rejected, not traded off.

**Payment card data (PCI-DSS)**
- Never store sensitive authentication data after authorization: full track data, CVV/CVC, PIN or PIN block.
- Prefer tokenization. Don't handle raw PAN where a provider SDK or token works.
- Mask PAN wherever displayed (last 4 digits at most).
- Card data never appears in logs, analytics, crash reports, screenshots or error messages.
- TLS 1.2+ for all transmission.
- Code changes are reviewed by someone other than the author before release (enforced by branch rules).

**Mobile (OWASP MASVS v2)**
| Area | Requirement |
|---|---|
| STORAGE | Sensitive data only in platform secure storage (Keychain/Keystore). |
| CRYPTO | Platform or vetted libraries only; no custom crypto; no hard-coded keys. |
| AUTH | Server-side authorization for every sensitive action; session timeout; step-up auth for high-risk actions. |
| NETWORK | Certificate pinning for production APIs; no cleartext traffic. |
| PLATFORM | Minimal permissions; protect sensitive screens; validate deep links. |
| CODE | Validate all input; no debug code or test endpoints in release builds. |
| RESILIENCE | Obfuscate release builds; root/jailbreak detection per risk assessment. |
| PRIVACY | Collect the minimum data. |

**Central Bank of Egypt**
- Every spec touching payments, onboarding/KYC, customer data or limits has a **Regulatory impact** section.
- Specific CBE requirements are confirmed with Compliance — never assumed by engineers or AI.

**Secrets**
- No secrets in code, committed config or CI logs. Use the approved secret store.

## II. Correctness and money
- Money uses integer minor units or exact decimals — never floating point.
- Financial operations are idempotent and safe to retry.
- State-changing financial actions leave an audit trail (who, what, when, result).
- Currency, rounding and time zones are explicit.

## III. Testing
- Every behavior change ships with tests.
- Money and business logic tests cover edge cases: zero, negative, limits (exactly at, above), rounding, duplicates.
- Critical flows (payment, login, onboarding) have integration or end-to-end coverage.
- A bug fix includes a test that fails before the fix.

## IV. Architecture and simplicity
- Follow the project's architecture; deviations need an ADR.
- Simplest solution that meets the spec. No speculative abstraction.
- Business logic is independent of UI/framework code.
- New dependencies need justification: maintenance, license, security record.

## V. Failure handling and observability
- No silent catches. User-facing errors never leak internals.
- Structured logs, free of sensitive data.
- Network calls define timeouts and safe retries.

## VI. Specs and process
- Every spec has: user story, acceptance criteria, edge cases, error states, **Security impact**, **Regulatory impact**, open questions.
- Ambiguities are resolved with `/speckit-clarify` or the Product Owner — never guessed.
- Humans approve plans and merge PRs. AI never merges, approves, deploys or touches production.

## VII. Review severity
| Severity | Meaning | Blocks merge gate |
|---|---|---|
| Blocker | Security flaw, money as float, wrong financial logic, criterion contradicted | Yes |
| Major | Likely bug, criterion missing, untested behavior change | Yes |
| Minor | Standards, readability, non-critical architecture/performance | No |
