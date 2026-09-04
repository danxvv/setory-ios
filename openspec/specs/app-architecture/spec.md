# app-architecture Specification

## Purpose
Organize the app target's sources into explicit layers — App, Domain, Persistence, AI, Media, Features, DesignSystem, and TestSupport — with inspectable dependency boundaries: SwiftData writes confined to store types, a single shared OpenRouter transport, AI orchestration held in observable flow types outside view code, navigation destinations registered exactly once through a typed route, and device-language resolution performed at the presentation boundary — all without changing user-visible behavior.

## Requirements

### Requirement: Layered source organization
The app target's sources SHALL be organized into named layer directories rather than by Swift type kind. The layers are `App/` (entry point, root scene, container construction, navigation routes), `Domain/` (SwiftData entities, value vocabulary, transient drafts, pure read-model computations), `Persistence/` (catalog seeding, catalog payload types, write stores), `AI/` (shared OpenRouter transport plus one directory per AI feature), `Media/` (exercise media delivery), `Features/<feature>/` (screens and feature-owned view state), `DesignSystem/` (reusable presentation components and shared view helpers), and `TestSupport/` (automated-test scaffolding).

Because the target uses `PBXFileSystemSynchronizedRootGroup`, nested directories join the target automatically; the restructure MUST NOT require project-file edits. Swift has no per-directory namespacing, so moving a file MUST NOT change any type name, and no file MUST gain or lose an `import` solely because it moved.

Each layer's dependency direction SHALL be enforceable by inspection of the sources:

- No file under `Domain/Entities/` references `Locale.current` or imports `SwiftUI`.
- No file under `Features/` calls `ModelContext.save()`, `ModelContext.rollback()`, or `ModelContext.insert(_:)`.
- No file outside `TestSupport/` reads `CommandLine.arguments`.
- Exactly one type performs an HTTP exchange with the OpenRouter endpoint.

#### Scenario: Every source file lives in a layer directory
- **WHEN** the app target's sources are enumerated after the restructure
- **THEN** every `.swift` file resides under one of the named layer directories, and no `Models/`, `Services/`, or `Views/` directory remains

#### Scenario: Moving files changes no type names
- **WHEN** the restructure's file moves are applied without any content edits
- **THEN** the app target compiles, and no type, protocol, or member has been renamed by the move alone

#### Scenario: Layer boundary invariants hold
- **WHEN** the sources are audited for the four boundary invariants above
- **THEN** each invariant holds with zero violations

### Requirement: Persistence write boundary
All writes to the SwiftData store SHALL be performed by store types that accept a `ModelContext`, not inside view bodies or view helper methods. Each store type owns one aggregate: finishing a logging day into a session with its ordered series, creating and updating routine templates, duplicating and deleting routine templates, and saving exercise edits.

Store operations SHALL preserve the current failure semantics exactly: a failed save rolls the context back so no partial write survives, and the failure is surfaced to the caller rather than swallowed. Views MUST NOT be the place where save failure is detected or handled.

The muscle-target metadata of written records MUST continue to be derived from the referenced `Exercise` records rather than copied at write time, so template muscle coverage and session muscles-worked stay consistent with the catalog.

#### Scenario: Finishing a day is testable without UI
- **WHEN** a unit test hands the workout store a set of draft series and an in-memory `ModelContext`
- **THEN** a session persists with one ordered series per draft, preserving order, reps, weight, and duration, with no view involved

#### Scenario: Failed save leaves no partial write
- **WHEN** a store operation's save fails
- **THEN** the context is rolled back, the store reports the failure to its caller, and a subsequent fetch returns the store's pre-operation contents

#### Scenario: Duplicating a template is testable without UI
- **WHEN** a unit test asks the template store to duplicate a template holding three ordered items
- **THEN** a second template persists with the same three items in the same order and the same target set counts, and its derived primary and secondary muscle coverage matches the original's

### Requirement: Shared OpenRouter transport
Both AI features — routine suggestion and photo exercise match — SHALL obtain their results from the OpenRouter REST API (`POST https://openrouter.ai/api/v1/chat/completions`, authenticated with the user's stored key as a Bearer token); inference never happens on-device. The HTTP exchange itself SHALL be performed by a single shared transport type that owns the endpoint URL, the request timeout, Bearer authorization, `URLError.cancelled` → `CancellationError` translation, and HTTP status → error mapping.

Each feature SHALL keep its own request builder and its own response parser; only the transport is shared. The shared error taxonomy, the shared chat-completion response envelope, and the resolution of the user's model-override preference SHALL each live in the AI shared layer, so neither feature reaches into the other's files for them.

The serialized request bodies MUST be byte-identical to the pre-restructure bodies for the same inputs: the same model, messages, system prompts, structured-output schemas, and catalog-subset contents including exercise ids and muscle-target raw values.

#### Scenario: Identical status mapping across both features
- **WHEN** the OpenRouter endpoint answers HTTP 402 to a suggestion request and to a photo match request
- **THEN** both features surface the same insufficient-credits error, with the same localized message and the same steer toward AI settings

#### Scenario: Cancellation is translated once
- **WHEN** the surrounding task is cancelled mid-request for either AI feature
- **THEN** the client throws `CancellationError` rather than a network error, and the flow returns silently with no error alert

#### Scenario: Request bytes are unchanged by the restructure
- **WHEN** a suggestion request body and a photo match request body are built from fixed inputs after the restructure
- **THEN** each is byte-identical to the body built from the same inputs before the restructure

### Requirement: AI flow orchestration outside view code
The orchestration each AI feature performs between the user's action and the presented result — fetching exercises and history from the store, building the request payload, calling the service, resolving returned exercise ids back to local `Exercise` records, and mapping thrown errors to presentable state — SHALL live in an observable flow type per feature, not in a `View`.

Resolved results MUST take their display name, muscle-target metadata, and media from the local `Exercise` records, never from the model response. Ids the local store does not know MUST be dropped during resolution.

The shared presentation shell for these flows — the no-key explanation with its route into AI settings, the in-flight progress state, the cancel action, and the failure alert offering retry plus a settings route for key and credit failures — SHALL exist once and be used by both features.

#### Scenario: Flow model resolves results headlessly
- **WHEN** a unit test drives a feature's flow model with a stubbed service and an in-memory store
- **THEN** the flow reaches its result state with each result carrying the local record's name and primary muscles, and no view is instantiated

#### Scenario: Unknown ids are dropped during resolution
- **WHEN** a stubbed service returns one id present in the local store and one absent from it
- **THEN** the flow's result state contains only the present one

#### Scenario: Both features share one failure shell
- **WHEN** either AI feature fails with an invalid-key error
- **THEN** the same alert shape appears — a localized message, a retry action, and an action opening AI settings

### Requirement: Single-registration navigation routes
Navigation destinations SHALL be expressed as a dedicated route type rather than as bare `String` values, and each destination SHALL be registered exactly once through a shared view modifier that any navigation stack needing those destinations applies.

Pushing an exercise detail screen and pushing an exercise progression screen MUST work identically from every stack that applies the modifier, and no stack MUST register the same destination a second time.

#### Scenario: Progression screen reachable from two tabs through one registration
- **WHEN** the user opens an exercise's progression screen from the Exercises tab and from the Progress tab
- **THEN** both pushes resolve through the same route type and the same single destination registration, and both screens render the same exercise

#### Scenario: No bare-String destinations remain
- **WHEN** the sources are audited for navigation destination registrations
- **THEN** no destination is registered for `String.self`, and the progression destination is registered in exactly one place

### Requirement: Presentation-boundary locale resolution
Ambient device-language resolution SHALL happen at the presentation boundary, not inside SwiftData entities. An entity's per-locale content accessors — display name, description, and instruction steps — SHALL take an explicit language code, and the convenience that resolves the current device language SHALL live in the presentation layer.

Resolution behavior MUST be unchanged: a user-modified exercise renders its stored text verbatim, an empty or missing translation for the requested language falls back to the canonical English value, and search continues to match both the resolved display name and the canonical English name so English dataset vocabulary stays findable on a Spanish device.

#### Scenario: Content resolution is verifiable without pinning the host language
- **WHEN** a unit test asks an exercise for its content in `es` and then in `en` on a test host running any device language
- **THEN** each call returns that language's content, with no dependency on the simulator's configured language

#### Scenario: Entities read no ambient locale
- **WHEN** the entity sources are audited
- **THEN** no file under `Domain/Entities/` references `Locale.current`

#### Scenario: Display sites resolve the device language
- **WHEN** the exercise library, detail screen, logging rows, and routine history render on a Spanish device
- **THEN** each shows the Spanish display name, exactly as before the restructure

### Requirement: Behavior preservation
The restructure SHALL NOT change user-visible behavior. Every requirement in the existing capability specs MUST continue to hold, and the existing unit and UI test suites MUST pass with only mechanical updates — renamed or relocated symbols — and no changes to assertions, expected on-screen text, accessibility identifiers, or launch arguments.

The restructure SHALL land as a sequence of individually verifiable steps, each leaving the app target building and both suites passing, rather than as a single sweeping commit.

#### Scenario: Existing suites pass unchanged
- **WHEN** the unit and UI test suites run against the restructured app
- **THEN** every test passes, and no test's assertions or expected strings were altered to make it pass

#### Scenario: Accessibility identifiers are stable
- **WHEN** the restructured app is inspected for the accessibility identifiers the UI tests query
- **THEN** every identifier is byte-identical to its pre-restructure value

#### Scenario: Each step is independently green
- **WHEN** any single step of the restructure sequence is applied on its own
- **THEN** the app target builds and both test suites pass at that point
