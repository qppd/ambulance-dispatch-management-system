#!/usr/bin/env python3
"""ADMS Flutter Web — Playwright end-to-end suite.

Runs the full scenario set against the *built* Flutter Web app (release build
served over HTTP) at five viewports, exercising the app through Flutter's
semantics (accessibility) tree so that selectors are semantic and stable rather
than pixel/coordinate based.

Scenarios (9; the horizontal-overflow check runs inside several of them)
------------------------------------------------------------------------
1. boot_welcome        App boots, semantics can be enabled, welcome screen renders.
2. nav_login           Semantic tap "Citizen Login"  -> login screen + URL updates.
3. form_validation     Empty "Sign In" submit        -> field-level validation text.
4. nav_register        Semantic tap "Create Account" -> register screen, wizard gate.
5. nav_staff_login     Semantic tap "Staff & Admin Login" -> staff portal.
6. deep_link           Direct load of #/staff-login  -> staff portal renders.
7. route_guard         Direct load of #/super-admin  -> redirected to welcome.
8. refresh_preserves   Reload after in-app navigation keeps the current screen.
9. console_clean       Zero page errors / unexpected console errors / failed requests.

`assert_no_hscroll` runs on the welcome, login and staff-login routes to catch
horizontal overflow at narrow viewports.

Flutter Web only exposes its DOM semantics tree after the
``flt-semantics-placeholder`` ("Enable accessibility") overlay is activated.
Playwright's actionability checks reject that 1px node at (-1,-1), so we trigger
it via a DOM click, then address widgets through ``flt-semantics[role=...]``.

Usage
-----
    python e2e_suite.py [BASE_URL]        # default http://127.0.0.1:5002/

Results are written to e2e_results.json and summarised as a matrix on stdout.
Exit code 0 iff every scenario passed at every viewport.
"""

from __future__ import annotations

import json
import os
import re
import sys
import time

from playwright.sync_api import sync_playwright

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else os.environ.get(
    "ADMS_E2E_URL", "http://127.0.0.1:5002/"
)

VIEWPORTS = [
    ("1280x720", 1280, 720),
    ("1024x768", 1024, 768),
    ("768x1024", 768, 1024),
    ("390x844", 390, 844),
    ("360x800", 360, 800),
]

# Console noise that is environmental rather than an application defect.
BENIGN_PATTERNS = [
    re.compile(p, re.I)
    for p in [
        r"WebGL",
        r"CONTEXT_LOST",
        r"GPU stall",
        r"SwiftShader",
        r"Automatic fallback to software WebGL",
        r"notification init error \(non-fatal\)",
        r"firebase_messaging/permission-blocked",
        r"TrustedTypes",
        r"Download the React DevTools",
        r"fbml",
        r"favicon",
    ]
]

# Texts that must be present on each screen (semantic, stable copy).
#
# The auth screens are responsive: `welcome_screen.dart:15`, `login_screen.dart:40`,
# `register_screen.dart:57` and `staff_login_screen.dart:43` all branch on
# `isWide = size.width > 800`. The wide (>800px) layouts show a branding panel
# with titles such as "Ambulance Dispatch Management" / "Create Your Account" /
# "Staff & Admin Portal"; the narrow (<=800px) layouts show a compact header
# ("ADMS / Ambulance Dispatch", "Sign Up", "Staff Portal") over the *same* form.
#
# So the assertions below only use copy that exists in BOTH branches. The
# branding titles are deliberately not asserted (they legitimately differ by
# width), while the shared form content is, so every viewport still gets a
# meaningful screen-identity check.
WELCOME_TEXTS = [
    "Ambulance Dispatch",  # "…Dispatch Management" (wide) / logo text (narrow)
    "Citizen Login",
    "Create Account",
    "Staff & Admin Login",
]
LOGIN_TEXTS = ["Enter your credentials", "Email", "Password"]
# Shared step-1 content of the register screen. The register form is a wizard:
# step 1 collects "Personal Information" (first/last name, phone) and tapping
# "Continue" reveals "Account Details" (email etc.), so only step-1 copy that is
# present immediately after navigation is asserted — the wide-only branding
# title is deliberately not asserted because it legitimately differs by width.
REGISTER_TEXTS = [
    "Sign Up",
    "Personal Information",
    "First Name",
    "Last Name",
    "Phone Number",
    "Continue",
]
# Shared form content of the staff portal (`_buildLoginContent`).
STAFF_TEXTS = [
    "Staff Sign In",
    "Select your role and enter credentials",
    "Email",
    "Password",
]


class ScenarioError(AssertionError):
    """Raised when a scenario assertion fails."""


def is_benign(text: str) -> bool:
    return any(p.search(text) for p in BENIGN_PATTERNS)


class Page:
    """Thin wrapper adding Flutter-semantics helpers and error capture."""

    def __init__(self, page):
        self.page = page
        self.page_errors: list[str] = []
        self.console_errors: list[str] = []
        self.console_warnings: list[str] = []
        self.failed_requests: list[str] = []
        # Requests the browser cancelled itself (net::ERR_ABORTED). These are
        # not server/network faults — e.g. an in-flight polling request that is
        # torn down when the context closes, or a navigation that supersedes
        # another. They are tracked separately so a genuine failure can never be
        # hidden among them.
        self.aborted_requests: list[str] = []
        page.on("pageerror", lambda e: self.page_errors.append(str(e)))
        page.on(
            "console",
            lambda m: (
                self.console_errors.append(m.text)
                if m.type == "error"
                else self.console_warnings.append(m.text)
                if m.type == "warning"
                else None
            ),
        )

        def _on_failed(r):
            rec = f"{r.resource_type} {r.url} :: {r.failure or 'failed'}"
            if r.failure and "ERR_ABORTED" in r.failure:
                self.aborted_requests.append(rec)
            else:
                self.failed_requests.append(rec)

        page.on("requestfailed", _on_failed)

    # -- semantics ---------------------------------------------------------

    def enable_semantics(self, timeout_ms: int = 20000) -> bool:
        """Activate Flutter's semantics tree via the accessibility overlay."""
        deadline = time.time() + timeout_ms / 1000
        while time.time() < deadline:
            try:
                found = self.page.evaluate(
                    """() => {
                        const el = document.querySelector('flt-semantics-placeholder');
                        if (!el) return false;
                        el.click();
                        return true;
                    }"""
                )
            except Exception:
                found = False
            if found:
                # Wait for the tree to actually populate.
                for _ in range(10):
                    self.page.wait_for_timeout(400)
                    if self.semantics_count() > 0:
                        return True
            self.page.wait_for_timeout(500)
        return self.semantics_count() > 0

    def semantics_count(self) -> int:
        return self.page.locator("flt-semantics").count()

    def texts(self) -> list[str]:
        return self.page.evaluate(
            """() => Array.from(document.querySelectorAll('flt-semantics'))
                 .map(e => (e.textContent || '').replace(/\\s+/g, ' ').trim())
                 .filter(Boolean)"""
        )

    def joined_text(self) -> str:
        return " \n ".join(self.texts())

    def screen_has(self, needle: str) -> bool:
        return needle in self.joined_text()

    def require_screen(self, needles: list[str], where: str) -> None:
        missing = [n for n in needles if not self.screen_has(n)]
        if missing:
            raise ScenarioError(
                f"{where}: missing expected text {missing}; "
                f"screen head = {self.joined_text()[:300]!r}"
            )

    def tap_button(self, label: str, where: str) -> None:
        """Semantic tap on a widget addressed by its accessible label."""
        loc = self.page.locator('flt-semantics[role="button"]', has_text=label)
        if loc.count() == 0:
            # Some labels live on non-button semantics nodes (e.g. cards).
            loc = self.page.locator("flt-semantics", has_text=label)
        if loc.count() == 0:
            raise ScenarioError(
                f"{where}: no semantics node with label {label!r}; "
                f"available = {self.texts()[:8]}"
            )
        loc.last.click(force=True)
        self.page.wait_for_timeout(2500)

    def goto(self, fragment: str, wait_ms: int = 8000) -> None:
        self.page.goto(BASE_URL + fragment.lstrip("/"), wait_until="load")
        self.page.wait_for_timeout(wait_ms)
        self.enable_semantics()

    def reload(self, wait_ms: int = 8000) -> None:
        self.page.reload(wait_until="load")
        self.page.wait_for_timeout(wait_ms)
        self.enable_semantics()

    # -- assertions --------------------------------------------------------

    def assert_no_hscroll(self, where: str) -> None:
        metrics = self.page.evaluate(
            """() => ({
                 docScroll: document.documentElement.scrollWidth,
                 bodyScroll: document.body ? document.body.scrollWidth : 0,
                 inner: window.innerWidth,
             })"""
        )
        if metrics["docScroll"] > metrics["inner"] + 1:
            raise ScenarioError(
                f"{where}: horizontal overflow — scrollWidth="
                f"{metrics['docScroll']} > innerWidth={metrics['inner']}"
            )

    def unexpected_errors(self) -> dict[str, list[str]]:
        return {
            "page_errors": list(self.page_errors),
            "console_errors": [
                e for e in self.console_errors if not is_benign(e)
            ],
            "failed_requests": list(self.failed_requests),
        }


# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

def s_boot_welcome(p: Page, vp: str) -> None:
    p.goto("", wait_ms=9000)
    if p.semantics_count() == 0:
        raise ScenarioError("semantics tree never became available")
    p.require_screen(WELCOME_TEXTS, "welcome screen")
    p.assert_no_hscroll("welcome")


def s_nav_login(p: Page, vp: str) -> None:
    p.goto("", wait_ms=9000)
    p.tap_button("Citizen Login", "welcome -> login")
    p.require_screen(LOGIN_TEXTS, "login screen")
    if "#/login" not in p.page.url:
        raise ScenarioError(
            f"browser URL did not reflect navigation: {p.page.url!r}"
        )
    p.assert_no_hscroll("login")


def s_form_validation(p: Page, vp: str) -> None:
    p.goto("#/login?role=citizen")
    p.tap_button("Sign In", "empty submit")
    p.require_screen(
        ["Please enter your email", "Please enter your password"], "validation"
    )


def s_nav_register(p: Page, vp: str) -> None:
    p.goto("", wait_ms=9000)
    p.tap_button("Create Account", "welcome -> register")
    p.require_screen(REGISTER_TEXTS, "register screen")
    if "#/register" not in p.page.url:
        raise ScenarioError(
            f"browser URL did not reflect navigation: {p.page.url!r}"
        )
    # The register form is a two-step wizard; exercise the step-1 gate so the
    # scenario verifies the wizard actually runs rather than just rendering.
    p.tap_button("Continue", "register step-1 submit")
    p.require_screen(["Required"], "register step-1 validation")


def s_nav_staff_login(p: Page, vp: str) -> None:
    p.goto("", wait_ms=9000)
    p.tap_button("Staff & Admin Login", "welcome -> staff-login")
    p.require_screen(STAFF_TEXTS, "staff portal")
    if "#/staff-login" not in p.page.url:
        raise ScenarioError(
            f"browser URL did not reflect navigation: {p.page.url!r}"
        )


def s_deep_link(p: Page, vp: str) -> None:
    p.goto("#/staff-login")
    p.require_screen(STAFF_TEXTS, "deep link #/staff-login")
    p.assert_no_hscroll("staff-login (deep link)")


def s_route_guard(p: Page, vp: str) -> None:
    """Unauthenticated access to a protected route must land on welcome."""
    p.goto("#/super-admin")
    p.require_screen(WELCOME_TEXTS, "route guard #/super-admin")
    if any(t.startswith("Super Admin") for t in p.texts()):
        raise ScenarioError("protected super-admin UI rendered while logged out")
    p.assert_no_hscroll("welcome (after guard)")


def s_refresh_preserves(p: Page, vp: str) -> None:
    p.goto("", wait_ms=9000)
    p.tap_button("Citizen Login", "welcome -> login")
    p.require_screen(LOGIN_TEXTS, "login (pre-refresh)")
    p.reload()
    p.require_screen(LOGIN_TEXTS, "login (post-refresh)")
    if "#/login" not in p.page.url:
        raise ScenarioError(f"refresh lost the route: {p.page.url!r}")


def s_console_clean(p: Page, vp: str) -> None:
    """Drive a realistic flow, then assert nothing unexpected was logged."""
    p.goto("", wait_ms=9000)
    p.tap_button("Citizen Login", "welcome -> login")
    p.tap_button("Forgot password?", "login -> forgot password")
    p.goto("#/register?role=citizen")
    p.goto("")
    errs = p.unexpected_errors()
    problems = {k: v for k, v in errs.items() if v}
    if problems:
        raise ScenarioError(f"unexpected browser errors: {problems}")


SCENARIOS = [
    ("boot_welcome", s_boot_welcome),
    ("nav_login", s_nav_login),
    ("form_validation", s_form_validation),
    ("nav_register", s_nav_register),
    ("nav_staff_login", s_nav_staff_login),
    ("deep_link", s_deep_link),
    ("route_guard", s_route_guard),
    ("refresh_preserves", s_refresh_preserves),
    ("console_clean", s_console_clean),
]


def main() -> int:
    results: dict[str, dict[str, dict]] = {}
    started = time.time()

    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        for vp_name, width, height in VIEWPORTS:
            results[vp_name] = {}
            for scen_name, scen_fn in SCENARIOS:
                context = browser.new_context(
                    viewport={"width": width, "height": height}
                )
                page = Page(context.new_page())
                entry: dict = {"status": "PASS", "detail": ""}
                try:
                    scen_fn(page, vp_name)
                    # Fold in any errors accumulated but not raised by the
                    # scenario itself (scenarios 1-8 still check errors only in
                    # console_clean, but page errors are always a failure).
                    if page.page_errors:
                        raise ScenarioError(
                            f"pageerror(s): {page.page_errors[:3]}"
                        )
                except Exception as exc:  # noqa: BLE001 - report everything
                    entry["status"] = "FAIL"
                    entry["detail"] = str(exc)[:500]
                finally:
                    entry["console_errors"] = len(
                        [e for e in page.console_errors if not is_benign(e)]
                    )
                    # Snapshot before closing: `context.close()` cancels any
                    # in-flight request, which fires requestfailed with
                    # ERR_ABORTED. Counting after close would attribute those
                    # teardown aborts to the scenario.
                    entry["failed_requests"] = len(page.failed_requests)
                    entry["aborted_requests"] = len(page.aborted_requests)
                    context.close()
                results[vp_name][scen_name] = entry
                mark = "PASS" if entry["status"] == "PASS" else "FAIL"
                print(
                    f"[{mark}] {vp_name:<10} {scen_name:<18} "
                    f"{entry['detail'][:140]}"
                )
        browser.close()

    elapsed = round(time.time() - started, 1)
    total = sum(len(v) for v in results.values())
    passed = sum(
        1
        for v in results.values()
        for e in v.values()
        if e["status"] == "PASS"
    )

    print("\n=== E2E matrix (rows=viewport, cols=scenario) ===")
    names = [n for n, _ in SCENARIOS]
    print(f"{'viewport':<11}" + "".join(f"{n[:13]:<15}" for n in names))
    for vp_name, _w, _h in VIEWPORTS:
        row = f"{vp_name:<11}"
        for n in names:
            row += f"{results[vp_name][n]['status']:<15}"
        print(row)

    print(f"\n{passed}/{total} scenarios passed in {elapsed}s")

    out = {
        "base_url": BASE_URL,
        "viewports": [v[0] for v in VIEWPORTS],
        "elapsed_seconds": elapsed,
        "passed": passed,
        "total": total,
        "results": results,
    }
    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "e2e_results.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    print(f"results -> {out_path}")

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
