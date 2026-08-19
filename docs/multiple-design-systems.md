# Multiple App Design Systems

## Goal

StarterApp should remain the canonical iOS production template while supporting multiple app-specific visual identities.

The goal is **not** to turn StarterApp into a collection of app forks. A generated app should share the same production foundation while choosing a coherent design system at bootstrap time.

## Design principles

### 1. Separate foundation from visual design

Keep these shared:

- app lifecycle and launch routing
- onboarding infrastructure
- purchase management and StoreKit integration
- AppFoundation integration
- privacy manifest and localization setup
- testing infrastructure
- developer studios
- template/bootstrap/repair infrastructure

The design system should own the visual language and reusable UI composition.

### 2. Define a small design-system contract

The contract should cover the things that need to stay visually coherent across an app:

- color roles and semantic colors
- typography roles
- spacing scale
- corner-radius scale
- shadows/materials
- buttons and controls
- cards and containers
- navigation surfaces
- common empty/loading/error states
- app-specific reusable components where they are genuinely part of the system

The contract should not attempt to abstract every SwiftUI view. Prefer concrete components and tokens over a giant configurable component library.

### 3. Keep design-system implementations isolated

Use a predictable structure so the generated project can contain one selected system without importing unrelated systems.

For example:

```text
DesignSystem/
└── <SelectedSystem>/
    ├── Colors.swift
    ├── Typography.swift
    ├── Spacing.swift
    ├── Components/
    └── Assets.xcassets
```

The exact structure can change during implementation; the important rule is that a design system has a clear ownership boundary.

### 4. Do not duplicate AppFoundation

AppFoundation should continue to provide shared infrastructure such as theme state and shared paywall/purchase components where appropriate.

A StarterApp design system should adapt or compose those primitives rather than creating a second competing global theme mechanism.

If AppFoundation's current APIs are too restrictive for multiple design systems, improve those APIs separately rather than embedding AppFoundation-specific workarounds into each system.

## Template and `mycli` integration

`template.yml` should expose a design-system selection as part of the template contract.

The generated `.mycli/project.yml` should persist the selected design system alongside the existing template metadata.

Example conceptually:

```yaml
designSystem: classic
```

The exact schema should be decided when implementation begins.

### `mycli new ios`

The generator should:

1. present the available design systems, or accept one non-interactively;
2. record the selection in generated project metadata;
3. include only the selected design-system source and assets;
4. generate configuration that points shared foundation code at the selected system.

### `mycli repair ios`

Repair should use the persisted design-system selection to determine what shared generated pieces belong to the project.

It must avoid overwriting app-owned customization merely because a design-system template changed.

### Changing a design system

Changing from one fundamentally different system to another should be an explicit migration, not an implicit consequence of running repair.

A future migration command can:

- verify the current system;
- show files/assets that will change;
- apply the new system;
- update `.mycli/project.yml`;
- leave app-specific business code untouched.

## Implementation phases

### Phase 1 — Contract

- Define the design-system boundary.
- Define token/component ownership.
- Add design-system metadata to `template.yml`.
- Persist the selected system in `.mycli/project.yml`.
- Document the ownership boundary between StarterApp and AppFoundation.

### Phase 2 — Extract the current system

Extract today's StarterApp visual language into the first named design system without intentionally changing the generated app's behavior or appearance.

This gives us a compatibility baseline and makes the new architecture useful immediately.

### Phase 3 — Build a genuinely different second system

Create a second system with meaningful differences in typography, spacing, shapes, colors, and component composition.

This is important: if the second system only changes a few colors, the abstraction has not been properly tested.

The second implementation should be difficult enough to expose assumptions that were accidentally baked into the first system.

### Phase 4 — Integrate with `mycli`

- Add interactive selection.
- Add non-interactive selection for automation.
- Persist the selection.
- Validate generated projects against the selected system.
- Define repair behavior.
- Add an explicit migration path for changing systems.

### Phase 5 — Validation

Add fixture/bootstrap coverage for every supported design system.

Validation should cover at least:

- template contract
- project generation
- XcodeGen generation
- Debug build
- Release build
- unit tests
- UI tests
- StoreKit configuration
- onboarding and launch routing
- paywall/settings UI
- alternate app icons
- Screenshot Studio
- Promo Video Studio
- privacy/localization files

The generated project must continue to work without committing a generated `.xcodeproj`.

## What should remain app-specific

StarterApp should not attempt to absorb every app's unique UI.

For example, a relationship app, screenshot utility, profile-card app, and network utility may each have domain-specific screens that should stay in the generated app.

The design system provides the shared visual grammar; the app provides the domain-specific composition.

## Non-goals

- Runtime switching between fundamentally different design systems.
- Infinite configuration of every component.
- Copying all existing app UI into StarterApp.
- Duplicating AppFoundation functionality.
- Creating a giant universal component framework before there are multiple real consumers.

## Success criteria

A developer can generate two apps from StarterApp with different design-system selections and both feel intentionally designed rather than recolored versions of the same template.

At the same time, the production foundation remains shared, and adding a third design system requires implementing the documented contract rather than forking StarterApp.
