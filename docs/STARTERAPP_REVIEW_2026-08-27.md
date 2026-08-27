# StarterApp Review Report — 2026-08-27

## Scope

Production-readiness review of the `master` branch of `hoangbkit/StarterApp`, focused on the template contract, XcodeGen configuration, StoreKit/purchase configuration, bootstrap validation, test coverage, and the documented development/release workflow.

This PR now includes the P0 implementation fix and its regression coverage.

## Verdict

**P0 fixed.** The template's normal purchase-manager construction now defaults to live StoreKit and only enables simulated purchases when the Debug-only simulation configuration requests it.

The overall template architecture is strong: the repository clearly separates reusable foundation from app-specific features, pins XcodeGen/AppFoundation versions, defines a machine-readable `template.yml` contract, includes bootstrap validation, and keeps optional capabilities out of the baseline.

## Findings

### P0 — `makePurchaseManager()` hard-coded simulated purchases — FIXED

**Location:** `StarterApp/App/AppConfiguration.swift`

The original implementation constructed `PurchaseManager` with `simulated: true` unconditionally. That conflicted with the documented contract that the normal/release path uses live StoreKit while the dedicated simulated scheme enables simulation.

The fix changes the production construction to use `isSimulatedPurchaseModeEnabled`. That value is now enabled only in Debug builds, when either the `APPFOUNDATION_PURCHASE_MODE=simulated` environment variable is present (as used by the `StarterApp Simulated` scheme) or the existing developer simulation preference is enabled. Release builds always resolve to live mode through the `#if DEBUG` guard.

A regression test was added to verify that the default configuration is not simulated. Preview construction remains explicitly simulated, which is appropriate for previews.

### P1 — Billing workflow was internally inconsistent — PARTIALLY ADDRESSED

**Locations:** `Makefile`, `StarterApp/App/AppConfiguration.swift`

The Makefile's `BILLING=live|simulated` workflow now has a matching application-side consumer: the `APPFOUNDATION_PURCHASE_MODE=simulated` environment variable is recognized by `AppConfiguration` in Debug builds.

Release remains protected from accidental simulation by compile-time gating.

A future improvement would be to consolidate all billing-mode semantics into one AppFoundation-facing helper, but this is no longer a production-blocking issue.

### P1 — Existing tests did not protect the critical release path — ADDRESSED

**Location:** `StarterAppTests/StarterAppTests.swift`

A regression test now verifies that the normal purchase configuration is not simulated by default. The existing build-conditional `PurchaseServiceFactory` test remains in place as additional protection for AppFoundation's effective-mode behavior.

The strongest possible end-to-end validation still requires building Debug/Release with Xcode and exercising both the normal and simulated schemes on a clean generated app.

### P2 — Template is intentionally iPhone-only

**Locations:** `project.yml`, `template.yml`

The template explicitly sets `TARGETED_DEVICE_FAMILY: '1'` and declares iPhone as its only default device family. This is consistent with the documented contract and is not a defect.

### P2 — Placeholder legal URLs are intentionally present, but bootstrap safety depends on validation

**Location:** `StarterApp/App/AppConfiguration.swift`

Support, privacy, and terms URLs intentionally point to `https://example.com/...`. This is acceptable for a template because the README requires replacing them before release and bootstrap validation rejects unresolved template values.

## Positive observations

- `template.yml` is a useful machine-readable contract with explicit identity, rename surfaces, optional features, lifecycle cleanup, and validation requirements.
- AppFoundation is pinned to exact version `0.1.11` in both the XcodeGen project and template contract.
- Generated Xcode projects/workspaces are intentionally kept out of source control.
- The template keeps widgets, SwiftData, app groups, and document types optional instead of forcing them into every generated app.
- StoreKit product identifiers are consistent between `template.yml`, `AppConfiguration.swift`, and `Configuration.storekit`.
- The test suite covers important template identity and onboarding invariants.
- `validate-template.sh` checks required files, executable validation scripts, identity invariants, and generated-project behavior when XcodeGen is available.
- `validate-bootstrap.sh` checks for unresolved StarterApp identity values and verifies that XcodeGen can generate the bootstrapped project.

## Release gate

Before publishing a new StarterApp template version:

1. Run template validation and bootstrap validation locally with XcodeGen/Xcode available.
2. Verify Debug simulated purchases with the `StarterApp Simulated` scheme.
3. Verify the normal Debug scheme uses live StoreKit unless the developer simulation preference is explicitly enabled.
4. Verify a Release build cannot enter simulated purchase mode.
5. Verify the generated app on a clean bootstrap checkout.
6. Only then publish the immutable template tag consumed by `mycli`.

## Review conclusion

**Architecture: strong.**

**Template contract: strong.**

**Validation strategy: good.**

**Purchase/release configuration: P0 fixed.**

The implementation is now aligned with the documented Debug simulation / Release live-StoreKit contract. The remaining validation should be performed with the actual Xcode toolchain before merging/tagging the template.
