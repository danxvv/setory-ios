## 1. Request payload and contract

- [x] 1.1 Add `userDescription: String?` and `muscle: Muscle?` to `PhotoMatchRequestPayload` in `gymapp/Models/PhotoMatchModels.swift`, documenting that both are optional hints and neither is ever persisted.
- [x] 1.2 Extend `PhotoMatchRequestBuilder.payload(exercises:photos:)` with `description: String? = nil` and `muscle: Muscle? = nil` (defaults keep existing call sites compiling): filter `exercises` to `primaryMuscles.contains(muscle)` when a muscle is given, trim the description, drop it when empty, and cap it at a new `maxDescriptionLength = 200` constant.
- [x] 1.3 Extend `PhotoMatchRequestBuilder.requestBody` so the text part emits the main muscle and the user description as their own labeled lines, kept distinct from the catalog JSON; verify the schema enum still derives from `payload.catalog.map(\.id)` so it narrows with the listing.
- [x] 1.4 Add a system-prompt rule telling the model to treat the description as a hint about the photos, to prefer the stated muscle, and to keep answering only with ids from the supplied catalog.

## 2. Request-builder unit tests

- [x] 2.1 In `gymappTests/PhotoMatchRequestBuilderTests.swift`, assert that a muscle selection narrows the catalog listing to primary-muscle matches and that the `response_format` enum contains exactly those ids.
- [x] 2.2 Assert that a secondary-muscle-only exercise is excluded by that filter, and that an unset muscle sends the full catalog.
- [x] 2.3 Assert description handling in the text part: present when supplied, absent when empty or whitespace-only, truncated at 200 characters, and never merged into the catalog JSON.

## 3. Capture-phase UI

- [x] 3.1 Add `@State` for the description text and the selected muscle to `PhotoMatchSheet`, plus a "Details" section below the photos section holding a single-line `TextField` (`photo-match-description-field`) and a muscle `Menu` mirroring `ExerciseFilterBar` — an "Any muscle" reset entry plus `Muscle.allCases` with a checkmark on the selection (`photo-match-muscle-menu`).
- [x] 3.2 Pass both values into `PhotoMatchRequestBuilder.payload(...)` inside `findMatches()`, and disable both controls while `isMatching`.
- [x] 3.3 Compute the count of locally stored exercises matching the selected muscle (in-memory filter over the fetched exercises, refreshed when the muscle changes); when it is zero, disable the find action and show a localized inline message telling the user to change or clear the main muscle (`photo-match-empty-muscle-note`).
- [x] 3.4 Confirm hints survive the results → "Try Other Photos" return to capture, and that dismissing the sheet discards them along with the photos.

## 4. Localization

- [x] 4.1 Add Spanish values in `gymapp/Localizable.xcstrings` for every new UI string (section header, field placeholder, muscle menu label, "Any muscle", empty-muscle note) and confirm `LocalizationTests` passes.

## 5. UI tests and verification

- [x] 5.1 Extend `gymappUITests/PhotoMatchUITests.swift` with a test that launches `-uitest-photo-match success`, attaches the fixture photo, types a description, selects a main muscle via the menu (`app.swipeUp()` first for offscreen items), and reaches the stubbed results.
- [x] 5.2 Add a UI test asserting the empty-muscle blocked state: find action unavailable and the inline note visible, with no results phase reached.
- [x] 5.3 Run `xcodebuild test -only-testing:gymappTests` and `scripts/uitest.sh -only-testing:gymappUITests/PhotoMatchUITests` against a scratch `-derivedDataPath`, and fix any fallout.
