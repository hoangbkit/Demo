# StarterApp Review Report — 2026-08-27

## Scope

Static production-readiness review of the `master` branch of `hoangbkit/StarterApp`, focused on the template contract, XcodeGen configuration, StoreKit/purchase configuration, bootstrap validation, test coverage, and the documented development/release workflow.

This PR is **review-only**. It does not change the StarterApp implementation; it records findings so they can be fixed and reviewed separately.

## Verdict

**Changes required before treating StarterApp as a production-safe canonical template.**

The overall template architecture is strong: the repository clearly separates reusable foundation from app-specific features, pins XcodeGen/AppFoundation versions, defines a machine-readable `template.yml` contract, includes bootstrap validation, and keeps optional capabilities out of the baseline.

However, there is one **critical purchase-mode issue** that conflicts with the repository's own release contract and can cause generated apps to use simulated purchases instead of live StoreKit.

## Findings

### P0 — `makePurchaseManager()` hard-codes simulated purchases

**Location:** `StarterApp/App/AppConfiguration.swift`

`makePurchaseManager()` constructs `PurchaseManager` with `simulated: true` unconditionally.

That conflicts with multiple documented guarantees:

- `README.md` says the simulated scheme is Debug-only and Release resolves to live StoreKit.
- `Makefile` documents `BILLING=live` and says Release builds always use live StoreKit.
- `StarterApp Simulated` is intended to be the explicit simulated-purchase path.

The current production app construction does not appear to select live mode for the normal app runtime. The test `testRequestedSimulationIsSafeForCurrentBuild()` only verifies `PurchaseServiceFactory.effectiveMode(for: .simulated)` and does not verify the mode actually used by `AppConfiguration.makePurchaseManager()`.

**Impact:** A generated app can ship with the purchase manager configured for simulation, making the template unsafe as a canonical production baseline and potentially preventing real StoreKit purchases from being exercised by the normal Release path.

**Recommended fix:** Make the normal purchase-manager construction resolve its mode from the build/runtime configuration so that normal Release uses live StoreKit, while the dedicated Debug simulation path explicitly enables simulation. Add a regression test that verifies the exact manager configuration used by `StarterAppApp` rather than only testing the factory helper in isolation.

### P1 — Billing workflow is internally inconsistent

**Locations:** `Makefile`, `StarterApp/App/AppConfiguration.swift`

The Makefile exposes `BILLING=live|simulated` and passes `DEVICECTL_CHILD_APPFOUNDATION_PURCHASE_MODE` when launching a device build. At the same time, `AppConfiguration.makePurchaseManager()` hard-codes `simulated: true`.

Even if AppFoundation has additional environment handling, the template currently has two competing sources of truth for purchase mode. The release contract should have one explicit and testable selection path.

**Recommended fix:** Consolidate purchase-mode selection in one configuration surface and test the `live`, `simulated`, Debug, and Release cases end-to-end at the application configuration boundary.

### P1 — Existing tests do not protect the critical release path

**Location:** `StarterAppTests/StarterAppTests.swift`

The suite has useful coverage for identity, URLs, persistence keys, product IDs, paywall configuration, and onboarding. It also contains a build-conditional simulation-mode test.

But there is no test asserting that `AppConfiguration.makePurchaseManager()` produces the expected live configuration for a normal Release build. This is exactly the path currently contradicted by the implementation/documentation.

**Recommended fix:** Add a regression test around the actual production purchase-manager construction, with the expected mode asserted for Debug simulation and Release live behavior.

### P2 — Template is intentionally iPhone-only

**Locations:** `project.yml`, `template.yml`

The template explicitly sets `TARGETED_DEVICE_FAMILY: '1'` and declares iPhone as its only default device family. This is consistent with the current documented contract and is therefore **not a defect**.

It should nevertheless remain an explicit product decision because generated apps will inherit the restriction unless `mycli` changes the selected configuration during bootstrap.

### P2 — Placeholder legal URLs are intentionally present, but bootstrap safety depends on validation

**Location:** `StarterApp/App/AppConfiguration.swift`

Support, privacy, and terms URLs intentionally point to `https://example.com/...`. This is acceptable for a template only because the README explicitly requires replacing them before release and `validate-bootstrap.sh` rejects unresolved template values.

This is a good pattern; keep the validation in place and ensure every future configuration surface containing placeholders is covered by the bootstrap scan.

## Positive observations

- `template.yml` is a useful machine-readable contract with explicit identity, rename surfaces, optional features, lifecycle cleanup, and validation requirements.
- AppFoundation is pinned to exact version `0.1.11` in both the XcodeGen project and template contract.
- Generated Xcode projects/workspaces are intentionally kept out of source control.
- The template keeps widgets, SwiftData, app groups, and document types optional instead of forcing them into every generated app.
- StoreKit product identifiers are consistent between `template.yml`, `AppConfiguration.swift`, and `Configuration.storekit`.
- The test suite covers important template identity and onboarding invariants.
- `validate-template.sh` checks required files, executable validation scripts, identity invariants, and generated-project behavior when XcodeGen is available.
- `validate-bootstrap.sh` checks for unresolved StarterApp identity values and verifies that XcodeGen can generate the bootstrapped project.

## Recommended release gate

Before tagging/publishing a new StarterApp template version:

1. Fix the purchase-mode issue and remove the duplicate/ambiguous billing-mode path.
2. Add a regression test for the actual production `PurchaseManager` construction.
3. Run template validation and bootstrap validation locally with XcodeGen/Xcode available.
4. Verify Debug simulated purchases and Release live StoreKit behavior on a clean generated app.
5. Only then publish the immutable template tag consumed by `mycli`.

## Review conclusion

**Architecture: strong.**

**Template contract: strong.**

**Validation strategy: good.**

**Purchase/release configuration: blocking issue.**

The template is close to being a very good canonical iOS baseline, but the purchase-mode construction needs to be corrected before it should be considered safe to generate production apps from it.
