# ADMS Audit Remediation — Final Report

**Repository:** ambulance-dispatch-management-system
**Scope:** remediation of HIGH (F1–F7), MEDIUM (G1–G8) and LOW findings, plus
verification via unit/widget/integration/emulator/E2E testing and a clean-clone
build.

**Final status: PASS**

| Gate | Before (`d911e1b`) | After | Evidence |
|---|---|---|---|
| `flutter analyze` | **169 issues** | **0 issues** | baseline + final both measured by running the tool |
| `flutter test` | **91 passed / 27 FAILED** | **144 passed / 0 failed** | 26 regression tests; every pre-existing test still passes |
| Integration test | — | **5/5 passed** | `integration_test/dispatch_lifecycle_test.dart`, `-d windows` |
| Rules + mirror (emulator) | — | **61/61 passed** | `tests/database-rules/*.mjs`, RTDB + Functions emulators |
| Playwright E2E | — | **45/45 passed** | 9 scenarios × 5 viewports, clean-clone release build |
| Clean-clone build | **failed** (assets gitignored) | **APK 59.3 MB + web OK** | fresh `git clone` → `pub get` → `build apk` → `build web` |
| Secrets committed | — | **none** | scan of clone for `*.jks`, `google-services.json`, `.env`, service accounts |

---

## 1. Findings reconciliation

### HIGH — F1–F7 (commit `5344475`)

| ID | Finding | Resolution | Verification |
|---|---|---|---|
| **F1/F3** | Driver identity used two competing key pairs | Canonical `assignedDriverId` / `assignedDriverName`; legacy `assignedUnitDriverId`/`Name` retained as **read-only** `fromJson` fallbacks so existing data still loads; `toJson` emits canonical keys only; all queries use canonical keys | Regression tests + integration lifecycle tests |
| **F2** | Incident lifecycle not enforced | Strictly linear `pending → acknowledged → dispatched → enRoute → onScene → transporting → atHospital → resolved`; `cancelled` from any non-terminal state; `resolved`/`cancelled` terminal. Driver UI now **requires** the `atHospital` step; `resolveIncident` pre-checks `atHospital` (DB rules authoritatively enforce) | 5 integration tests incl. "resolveIncident throws when not atHospital" |
| **F4** | ePCR writes could partially fail, losing data | Single atomic `set()` carrying every field; `updatePatientHistory` performs key-present-only updates; `_EpcrSection` added | Regression tests |
| **F5** | Database rules not deny-by-default | `database.rules.json` fully rewritten: auth/approval/active **GATE** (`auth != null && isApproved === true && isActive === true`), lifecycle `validate` rules, municipality mirror scoping, self-registration policy, superAdmin-only `/users` root read. Un-gated access limited to own `/users/{uid}` and public `/municipalities` read | **61 emulator tests** building a full authorization matrix |
| **F6** | Repo would not build from a clean clone | `.gitignore` no longer excludes `web/index.html`, `web/icons/`, `web/favicon.png`, `lib/firebase_options.dart`, Android `mipmap-*/*.png`, iOS/macOS `Assets.xcassets/**/*.png`, `linux/flutter/ephemeral/**`. A blanket `*.png` rule had excluded platform launcher icons | Clean-clone APK + web build both succeed |
| **F7** | Role guard only covered some routes | `AppRoutes.roleForLocation` covers every role root **and** sub-paths; `citizenLogin` explicitly excluded so it stays reachable | E2E `route_guard` scenario at all 5 viewports |

### MEDIUM — G1–G8

| ID | Finding | Resolution |
|---|---|---|
| **G1** | Dead providers `usersByRoleProvider`, `userByIdProvider`, `UserService.watchUsersByRole`, `UserService.watchUser` | **Removed** — zero callers, and they queried the now superAdmin-only `/users` root |
| **G2** | `withOpacity` deprecation (131 infos) | Migrated to `withValues(alpha: …)` |
| **G3** | Remaining analyzer infos | **Fully resolved** — analyzer is at 0 (includes `DropdownButtonFormField.value → initialValue`, `Radio` → `RadioGroup` ancestor, `use_build_context_synchronously` ×8 via `context.mounted`, `unnecessary_underscores` ×14, `sort_child_properties_last`, `curly_braces_in_flow_control_structures` ×18) |
| **G4** | Invite feature dead — tokens were never consumed by any registration flow | Rules branch kept (harmless, create-only for own-municipality municipalAdmin); **staff screen UI converted** from a fake-token invite dialog to an honest "How to Add Crew" dialog explaining self-registration + approval |
| **G5** | `driver_locations` node unused by live code | **Documented, not changed.** Verified: 0 references in `lib/`, but rules do cover it. Live driver locations are in `units`. Keeping rules coverage is defence-in-depth |
| **G6** | Raw `Error: $e` exception text in snackbars | **Fixed** — shared `userErrorMessage()` helper; **47 call sites across 16 files**; 0 residual raw interpolations (verified by scan) |
| **G7** | `forgot_password_screen` used `e.toString()` | **Fixed** — same helper |
| **G8** | `user_management` dropdown overflow | Fixed earlier |

### LOW

| Finding | Resolution |
|---|---|
| ~24 files corrupted by PowerShell `Get-Content`/`Set-Content` round-trip (UTF-8 → mojibake) | Repaired via cp1252→UTF-8 re-encode; full-tree sweep over 822 files reports **0** markers |
| Brace-rewriting script wrongly added `{` to collection-`if`s in 4 screens | Repaired manually |
| Dead code: duplicate `_actionFor` in `driver_dashboard.dart` | Removed (duplicate copies; `_availableActions` is the live one) |
| `admin.database.ServerValue.TIMESTAMP` undefined under firebase-admin v13 | `functions/audit.js` writes `new Date().toISOString()`, matching `AuditEntry.fromJson`'s `DateTime.parse` |
| `withSecurityRulesDisabled` returns `undefined` in rules-unit-testing v6 | Test helpers capture values inside the callback |
| `ref.listen` inside `Notifier.build()` never fires under Riverpod 3.3.1 | `SystemConfigNotifier._load()` performs a one-shot `fetchSystemConfig()` |

### Newly found during verification (not in the original audit)

| Finding | Severity | Resolution |
|---|---|---|
| **Browser URL did not reflect in-app navigation on web.** `GoRouter.optionURLReflectsImperativeAPIs` defaults to `false`, so `context.push(...)` left the address bar on the previous location: refresh dropped the user back to the welcome screen, shared links pointed at the wrong screen, and Back had no meaningful URL. Root-caused by inspecting `history.state` (the pushed route was stored under `imperativeMatches` while `location` stayed `/`) and confirmed in go_router source (`router.dart:348`, `parser.dart:262`). | Real user-facing bug | Fixed by enabling `optionURLReflectsImperativeAPIs`. Verified in Chromium: tap → `/#/login?role=citizen`, refresh keeps login, Back walks login → welcome |
| `debugLogDiagnostics: true` hardcoded — logged every navigation to the browser console in release builds | Low (information leak) | Gated on `kDebugMode` |
| Register form is a two-step **wizard**; "Email Address" is on step 2, not step 1 | Documentation of app behaviour | E2E asserts step 1 invariants + the "Continue" validation gate |

---

## 2. Test results

### Unit / widget — 144 passed, 0 failed

Baseline at `d911e1b` (pre-audit) was **91 passed / 27 FAILED** — measured by
checking out that commit in a separate clone and running `flutter test`. So the
suite went from 27 failures to none while growing from 118 to 144 tests, and all
pre-existing tests still pass (nothing was deleted, weakened or skipped to reach
green).

The 27 baseline failures, by file:

| Failures | File | Nature |
|---|---|---|
| 9 | `test/widgets/system_settings_screen_test.dart` | screen could not save/notify |
| 7 | `test/widgets/user_management_screen_test.dart` | screen could not list users |
| 5 | `test/services/system_config_notifier_test.dart` | `SystemConfigNotifier` stuck in `AsyncLoading` |
| 5 | `test/widgets/dispatch_map_test.dart` | `FlutterMap` never built (0 widgets found) |
| 1 | `test/widget_test.dart` | smoke test |

The two structural causes behind most of these were fixed as part of the
remediation: Riverpod 3.3.1 never fires `ref.listen` registered inside
`Notifier.build()`, so `SystemConfigNotifier` never left the loading state
(fixed with a one-shot `_load()`); and `DispatchMapWidget` depended on a Mapbox
token/`dotenv` that is absent in tests (fixed with an optional `tileProvider`
param and an `isInitialized` guard).

Includes 26 regression tests across two files:

- `test/regressions/audit_fixes_regression_test.dart` — F1–F4 driver keys, lifecycle, ePCR persistence, router guards
- `test/regressions/user_error_message_test.dart` — G6/G7: every well-known Firebase/platform code maps to a human sentence, and **no** mapped input ever returns its own `toString()`

### Integration — 5/5 passed (`-d windows`)

```
00:00 +0: Dispatch lifecycle — end-to-end full lifecycle from citizen report to resolution
00:00 +1: Dispatch lifecycle — end-to-end cancel dispatch frees the assigned unit
00:00 +2: Dispatch lifecycle — end-to-end resolveIncident throws when the incident is not atHospital
00:00 +3: Dispatch lifecycle — end-to-end resolveIncident proceeds from atHospital
00:00 +4: Dispatch lifecycle — end-to-end driver location update goes through dispatch service
00:00 +5: All tests passed!
```

### Database rules + mirror — 61/61 passed

```
ℹ tests 61
ℹ pass 61
ℹ fail 0
ℹ cancelled 0
```

Command (Java on PATH, no `.firebaserc` in repo, so `--project demo-adms` is required):

```
firebase emulators:exec --only database,functions --project demo-adms \
  "node --test --test-concurrency=1 tests/database-rules/rules.test.mjs tests/database-rules/mirror-sync.test.mjs"
```

`--test-concurrency=1` is required when the rules and mirror files share one
emulator instance.

> **Note on a non-reproducible failure seen mid-session:** two runs reported
> `56 pass / 5 fail`, all in `mirror-sync`, with the Functions emulator logging
> *"Failed to load function definition from source … Timeout after 10000"*. This
> was **not** a code fault. The five function modules call `admin.database()` at
> module load (`audit.js:11`, `dispatch.js:15`, `invites.js:11`,
> `notifications.js:11`, `users.js:32`), and firebase-admin v13 throws "Can't
> determine Firebase Database URL" unless `databaseURL` is present — which the
> Functions emulator supplies via `FIREBASE_CONFIG`. Loading `index.js` directly
> with those env vars set succeeds in **0.4 s**. The timeout was the Firebase
> CLI's loader losing a race against OneDrive sync I/O on this machine. The
> final solo run loaded all six functions and passed 61/61.

---

## 3. Playwright E2E matrix

**45/45 passed** — 9 scenarios × 5 viewports, against the **clean-clone release
build of the final commit `acd5c4b`** served over HTTP. Error totals for the run:
**0 console errors, 0 failed requests, 0 aborted requests.**

| Scenario | 1280×720 | 1024×768 | 768×1024 | 390×844 | 360×800 |
|---|---|---|---|---|---|
| `boot_welcome` | PASS | PASS | PASS | PASS | PASS |
| `nav_login` | PASS | PASS | PASS | PASS | PASS |
| `form_validation` | PASS | PASS | PASS | PASS | PASS |
| `nav_register` | PASS | PASS | PASS | PASS | PASS |
| `nav_staff_login` | PASS | PASS | PASS | PASS | PASS |
| `deep_link` | PASS | PASS | PASS | PASS | PASS |
| `route_guard` | PASS | PASS | PASS | PASS | PASS |
| `refresh_preserves` | PASS | PASS | PASS | PASS | PASS |
| `console_clean` | PASS | PASS | PASS | PASS | PASS |

Totals for the run: **0 console errors, 0 failed requests, 0 aborted requests.**

### How the suite drives the app

Flutter Web renders to a `<canvas>` and exposes no ordinary DOM for its widgets.
It only publishes a DOM **semantics tree** (`flt-semantics` nodes) after the
"Enable accessibility" overlay is activated. That overlay is a 1px node at
(-1, 1), so Playwright's actionability checks reject a normal click; the suite
activates it with a direct DOM `click()` via `page.evaluate`, then addresses
widgets by accessible role and label:

```python
page.locator('flt-semantics[role="button"]', has_text="Citizen Login")
```

Selectors are therefore **semantic and stable** against layout/CSS changes, and
the suite exercises the same tree a screen-reader user would.

### What each scenario covers

- **boot_welcome** — app boots, semantics become available, welcome screen renders, no horizontal overflow
- **nav_login / nav_register / nav_staff_login** — semantic tap navigates to the right screen **and** the browser URL updates (regression guard for the URL-sync fix)
- **form_validation** — empty "Sign In" submit surfaces "Please enter your email" / "Please enter your password"; register asserts the step-1 "Continue" gate surfaces "Required"
- **deep_link** — direct load of `#/staff-login` renders the staff portal
- **route_guard** — direct load of `#/super-admin` while logged out redirects to welcome, and no protected UI renders
- **refresh_preserves** — reload after in-app navigation keeps the current screen (regression guard for the URL-sync fix)
- **console_clean** — drives a realistic multi-screen flow, then asserts zero page errors, zero unexpected console errors and zero failed requests

### Responsive-copy caveat

The auth screens branch on `isWide = size.width > 800` (`welcome_screen.dart:15`,
`login_screen.dart:40`, `register_screen.dart:57`,
`staff_login_screen.dart:43`). Wide layouts show branding titles ("Ambulance
Dispatch Management", "Create Your Account", "Staff & Admin Portal"); narrow
layouts show compact headers over the **same form**. Assertions therefore use
copy present in **both** branches (the shared form content), so every viewport
gets a real screen-identity check rather than one layout's copy. This was
corrected after the first run failed 15 assertions at ≤768px — the failures were
in the test's expectations, not the app.

### Error capture and filtering

Recorded: `pageerror`, console errors, failed requests. Filtered as
environmental noise: WebGL/SwiftShader fallback warnings, `CONTEXT_LOST`, GPU
stall, Flutter's non-fatal `firebase_messaging/permission-blocked` notification
init message, TrustedTypes debug lines.

Browser-cancelled requests (`net::ERR_ABORTED`) are counted **separately** in
`aborted_requests`, and counts are snapshotted before `context.close()` —
closing the context cancels anything in flight and would otherwise attribute
teardown to the scenario. One such abort at 768×1024 was investigated and
confirmed benign: the route was loaded, failures captured for 13 s (0 failures),
then the context closed.

---

## 4. Clean-clone build (final commit `acd5c4b`)

```
git clone <repo> adms-clone-final      # 245 files, HEAD = acd5c4b
cd adms-clone-final/source/flutter/adms
flutter pub get                        # Got dependencies!
flutter build apk --release            # √ Built app-release.apk (59.3 MB)
flutter build web --release            # √ Built build\web (main.dart.js 4.1 MB, 37 files)
```

The E2E suite in §3 was then run against **this** build, so the browser evidence
and the build evidence come from the same artefact.

Secrets scan of the clone returned **none** for `*.jks`, `*.keystore`,
`google-services.json`, `GoogleService-Info.plist`, `.env`, `*serviceAccount*`,
`*.pem`. `lib/firebase_options.dart` contains only public client identifiers
(apiKey, projectId, appId, messagingSenderId) — safe to commit and required for
the build to succeed.

---

## 5. Remaining issues / accepted trade-offs

| Item | Status | Rationale |
|---|---|---|
| **Invite tokens are never consumed** | Accepted | No registration flow reads tokens; the feature was dead before the audit. Rules keep a create-only branch for own-municipality municipalAdmin (harmless). The staff screen no longer advertises the broken flow. If invites are wanted later, a registration flow must be built to consume them |
| **`driver_locations` node unused** | Accepted | Live driver locations are in `units`. Rules still cover the node (defence-in-depth), so no security gap |
| **Functions require a `databaseURL` at module load** | Accepted | Standard firebase-admin behaviour; the Functions runtime supplies it via `FIREBASE_CONFIG`. Only matters for ad-hoc local `require()` outside the emulator |
| **`cleanupExpiredInvites` needs the Pub/Sub emulator** | Accepted | Skipped under `--only database,functions`; it is a daily scheduler job, not on the auth/data critical path |
| **Functions engines pin node 20, host has node 24** | Cosmetic | CLI warns and runs on 24 successfully. Production uses the pinned 20 |

## 6. Environment limitations

- **Windows + OneDrive** working directory: OneDrive sync occasionally locks files under `build/` (Gradle "Unable to delete directory" → clear `build/` and retry) and added enough I/O latency to trip the Firebase CLI's 10 s functions-loader timeout twice.
- **No remote configured** — commits `5344475`, `bbaf669`, `fc7b328`, `acd5c4b` are local; clean-clone verification used a local `git clone`.
- **E2E is read-only public flows only** (welcome, login form validation, route-guard redirect) — no real Firebase credentials or writes were used, so authenticated dashboards are not E2E-covered.
- **Integration tests target `-d windows`**, not Android/iOS, since no emulator/device farm was available.
- **`pubspec.lock` pins** caused ~107 packages to report newer available versions; unrelated to the findings and left untouched to preserve reproducibility.

## 7. Commits

| Commit | Contents |
|---|---|
| `5344475` | Audit remediation: F1–F7, MEDIUM/LOW findings, rules hardening, regression tests (94 files) |
| `bbaf669` | Fix clean-clone build: un-ignore platform app icon assets (31 files) |
| `fc7b328` | Fix web URL sync; replace raw exception text with friendly messages; add E2E harness |
| `acd5c4b` | Harden E2E error classification; gate router diagnostics to debug |

Working tree is clean; no secrets, build outputs or generated test artefacts are tracked.

---

## 8. Final status

```
STATUS: PASS
```

| Requirement | Result |
|---|---|
| HIGH findings F1–F7 fixed and verified | **PASS** — all 7; lifecycle integrity proven by integration tests, rules by 61 emulator tests |
| MEDIUM findings G1–G8 fixed and verified | **PASS** — 6 fixed, 2 accepted with written rationale (G4 rules branch, G5 unused node) |
| LOW findings addressed | **PASS** — mojibake repaired across 822 files (0 markers), dead code removed, API deprecations migrated |
| No test deleted, weakened or skipped to reach green | **PASS** — suite grew 118 → 144; all pre-existing tests still run and pass |
| `flutter test` reaches 0 failures | **PASS** — 144 passed / 0 failed (baseline was 27 failures) |
| `flutter analyze` clean | **PASS** — 0 issues (baseline 169) |
| Firebase rules never weakened to pass tests | **PASS** — rules tightened to deny-by-default with a GATE; the authorization matrix is exercised by 61 emulator tests |
| Playwright E2E uses semantic/stable selectors | **PASS** — drives Flutter's semantics tree by role + accessible label, no coordinates |
| E2E covers 5 viewports | **PASS** — 1280×720, 1024×768, 768×1024, 390×844, 360×800; 45/45 |
| E2E inspects console/network errors | **PASS** — 0 pageerrors, 0 unexpected console errors, 0 failed requests; environmental noise filtered explicitly |
| No secrets committed | **PASS** — clone scan clean; `firebase_options.dart` holds public client IDs only |
| Repo builds from clean clone | **PASS** — `git clone` → `pub get` → `build apk` (59.3 MB) → `build web` |
| Report includes findings reconciliation, tests, E2E matrix, remaining issues, limitations | **PASS** — this document |

No claim in this report is asserted without a recorded execution: the baseline
figures come from checking out `d911e1b` in a separate clone and running the
tools, and every "after" figure comes from running the same tools on the final
commit `acd5c4b`.
