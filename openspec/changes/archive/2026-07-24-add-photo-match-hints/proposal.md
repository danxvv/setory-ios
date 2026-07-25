## Why

Photo matching currently sends the model nothing but pixels and the entire catalog (1300+ exercises), so a photo of a generic cable stack or a partially-framed machine comes back with plausible-looking matches from the wrong muscle group. The user standing in front of the machine usually knows something the photo does not convey — "the seat pushes forward", "it's for chest" — and today has no way to tell the model. Letting the user add one line of context and pick the main muscle turns an ambiguous guess into a constrained lookup.

## What Changes

- The photo match capture phase gains two optional inputs alongside the photos: a short free-text description and a single main-muscle selection drawn from the existing `Muscle` enum.
- When a main muscle is selected, the catalog listing sent to OpenRouter is filtered to exercises whose **primary** muscles include it. Because the strict response schema's `exerciseId` enum is built from the catalog that was sent, the model is structurally unable to return an exercise outside the chosen muscle.
- When a description is entered, it is included as a labeled line in the user message's text part, trimmed and length-capped.
- Both inputs are optional and default to off: with neither set, the request is byte-for-byte the request sent today.
- A muscle whose filtered catalog is empty blocks the request with an inline message instead of sending an empty schema enum (which OpenRouter would reject).
- Photos remain required — the description alone never triggers a match — and both new inputs stay transient like the photos: never persisted, discarded with the sheet.

## Capabilities

### New Capabilities

None. This extends the existing photo-match flow rather than introducing a new capability.

### Modified Capabilities

- `photo-exercise-match`: adds a requirement for the optional description and main-muscle hints in the capture phase; amends the request-contract requirement so the catalog listing is the muscle-filtered subset when a muscle is chosen and the text part carries the user's description and stated muscle; adds the empty-filtered-catalog guard; extends the deterministic-test-hook requirement so automated tests can drive the new inputs.

## Impact

- **Models**: `PhotoMatchRequestPayload` gains the user description and selected muscle (both optional) — a source-level change to a struct used only by the request builder, the service protocol, and their tests.
- **Services**: `PhotoMatchRequestBuilder` (catalog filtering, prompt text, system-prompt rules), `PhotoExerciseMatchService` (payload construction unchanged in shape; validation still keys off the sent catalog).
- **Views**: `PhotoMatchSheet` capture phase gains a description field and a muscle menu, plus the disabled/blocked state for an empty filtered catalog.
- **Localization**: new UI strings need Spanish values (`LocalizationTests` fails otherwise); muscle names already localize via `Muscle.displayName`.
- **Tests**: `PhotoMatchRequestBuilderTests` (filtering, description, schema enum), `PhotoMatchUITests` (new inputs, blocked state).
- **External contract**: unchanged endpoint, unchanged model override, unchanged response schema shape — only the contents of the catalog listing and the text part differ. No migration, no persisted data, no breaking changes.
