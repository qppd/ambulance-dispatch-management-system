# ADMS end-to-end tests (Flutter Web)

Playwright suite that drives the **built** Flutter Web app (release build served
over HTTP) through five viewports.

## Why semantics, not coordinates

Flutter Web renders no ordinary DOM for its widgets — everything lives on a
`<canvas>`. It only exposes a DOM **semantics tree** (nodes named
`flt-semantics`) after the "Enable accessibility" overlay
(`flt-semantics-placeholder`) is activated.

That overlay is a 1px node positioned at (-1, -1), so Playwright's actionability
checks reject a normal `.click()` on it. The suite activates it with a direct
DOM `click()` via `page.evaluate`, then addresses widgets by their accessible
role and label:

```python
page.locator('flt-semantics[role="button"]', has_text="Citizen Login")
```

This keeps selectors semantic and stable against layout/CSS changes, and it
means the suite exercises the same accessibility tree a screen-reader user
would.

## Responsive copy caveat

The auth screens branch on `isWide = size.width > 800` (`welcome_screen.dart:15`,
`login_screen.dart:40`, `register_screen.dart:57`, `staff_login_screen.dart:43`).
The wide layouts show branding titles ("Ambulance Dispatch Management",
"Create Your Account", "Staff & Admin Portal"); the narrow layouts show compact
headers over the same form.

Assertions therefore use copy that exists in **both** branches (the shared form
content), so every viewport gets a real screen-identity check rather than a
single layout's copy. The register screen is additionally a two-step wizard —
the suite asserts step 1 and that the "Continue" gate surfaces validation.

## Running

```bash
# 1. Build the app
cd source/flutter/adms && flutter build web --release

# 2. Serve it (any static server with SPA fallback works)
node serve.js <path-to>/build/web 5000

# 3. Run the suite
python e2e_suite.py http://127.0.0.1:5000/
```

Exit code is 0 only if every scenario passed at every viewport. Results are
written to `e2e_results.json`.

## Error capture

The suite records `pageerror`, console errors and failed requests, and filters
out environmental noise (WebGL/SwiftShader fallback warnings, Flutter's
non-fatal `firebase_messaging/permission-blocked` notification init message,
TrustedTypes debug lines).

Requests the browser cancels itself (`net::ERR_ABORTED`) are counted
separately in `aborted_requests`, because `context.close()` cancels anything
still in flight — counting those as failures would attribute teardown to the
app. Snapshots are taken *before* the context is closed for the same reason.
