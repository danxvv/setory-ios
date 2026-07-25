# Design — Photo Exercise Match

## Context

The app already has a complete BYOK OpenRouter pipeline for routine suggestions: `APIKeyStoring`/`KeychainAPIKeyStore`, `OpenRouterSuggestionService` (chat completions + strict JSON-schema structured outputs), `SuggestionResponseParser` (envelope decoding, embedded-error detection, HTTP status → `SuggestionError` mapping), SwiftUI `@Entry` environment injection, and `-uitest-ai` launch-argument stubbing. Exercise selection for routine templates is value-type-first: pickers return `[Exercise]` via a callback and `TemplateDraft.apply(to:in:)` is the only persistence point.

There is currently **zero** camera/photo code in the repo: no `PhotosUI`, no `UIImagePickerController`, no AVFoundation, and no Info.plist file (the project uses `GENERATE_INFOPLIST_FILE = YES` with `INFOPLIST_KEY_*` build settings in the pbxproj).

The photo match feature sends user photos plus a catalog listing to the same OpenRouter REST endpoint and gets back catalog exercise ids. Everything AI-related stays behind the REST contract — no on-device inference.

## Goals / Non-Goals

**Goals:**
- One-sheet flow from the template editor: capture/select photos → send → pick from matched exercises → appended to the template draft.
- Reuse the existing OpenRouter plumbing (key store, envelope parsing, error taxonomy, injection and stubbing patterns) rather than building a parallel stack.
- Strict-schema response constrained to real catalog ids, validated client-side against the local exercise store before anything reaches the UI.
- Deterministic UI tests with no camera or `PhotosPicker` interaction.

**Non-Goals:**
- No on-device vision/ML inference and no new backend.
- No photo persistence: photos live in memory for the duration of one request and are never written to disk or SwiftData.
- No entry point from the workout-logging screen or the exercise library in this change (template editor only).
- No creation of new custom exercises from photos — matching is strictly against the existing catalog (including custom exercises already in the store).
- No match history.

## Decisions

### 1. Same OpenRouter endpoint, multimodal user message

Reuse `POST https://openrouter.ai/api/v1/chat/completions` with the existing auth header and `response_format: json_schema (strict)`. The only contract difference: the user message `content` becomes a **content-parts array** — one `{"type":"text"}` part carrying the catalog payload and instructions, plus one `{"type":"image_url","image_url":{"url":"data:image/jpeg;base64,…"}}` part per photo. The existing `SuggestionPromptBuilder` ships `content` as a plain string, so the photo flow gets its own `PhotoMatchRequestBuilder` rather than bending the suggestion builder.

*Alternative considered*: a separate vision endpoint or provider — rejected; OpenRouter's chat completions API is already multimodal and the BYOK key/settings apply unchanged.

### 2. Full catalog with names in the prompt; ids enum-constrained in the schema

`SuggestionPromptBuilder.CatalogEntry` deliberately omits exercise names and caps at 200 entries — both wrong for vision matching, where the model must see names and cannot be pre-filtered (the photo's content is unknown until the model looks at it). The request builder sends the **entire catalog** (all ~1324 entries plus custom exercises) as compact JSON: `{id, name, equipment?, primaryMuscles}`. That is roughly 15–25k input tokens — acceptable for an explicit, user-initiated request. The response schema constrains `exerciseId` to an enum of the same ids (the proven trick from `responseSchema(exerciseIds:)`), with `maxItems` capping matches at 10.

*Alternative considered*: two-stage flow (model names the equipment → client filters by `Equipment` raw value → second request) — rejected: doubles latency and cost, and equipment metadata is optional on `Exercise`, so filtering would silently exclude valid matches.

### 3. Response payload: ordered matches with a confidence tier

```json
{ "matches": [ { "exerciseId": "gv0025", "confidence": "high" } ] }
```
`confidence` is a closed enum (`high`/`medium`/`low`) so the UI can group or badge results; matches arrive best-first. No free-text rationale — it inflates output tokens and the result list already shows name, muscles, and thumbnail from local data. Client-side validation drops unknown ids and duplicates (same pattern as catalog-constrained suggestion validation); an empty post-validation list is a normal "no matches" UI state, not an error.

### 4. New `PhotoExerciseMatchService` protocol beside the suggestion service

```swift
protocol PhotoExerciseMatchService: Sendable {
    func matchExercises(request: PhotoMatchRequestPayload) async throws -> PhotoMatchResult
}
```
`OpenRouterPhotoMatchService` mirrors `OpenRouterSuggestionService` (same key store, same `URLSession` injection, same 60 s timeout, same model resolution — see Decision 5). Injection adds a third `@Entry` in `AIEnvironment.swift`. Error handling **reuses `SuggestionError`** and the `SuggestionResponseParser` envelope/status mapping (extracted or made generic as needed) — `missingAPIKey`, `network`, `invalidKey`, `insufficientCredits`, `rateLimited`, `badResponse` all apply verbatim; the routine-specific `emptySuggestion` case is simply never thrown by this service.

*Alternative considered*: a new `PhotoMatchError` enum — rejected; it would duplicate six localized strings and the settings-pointer logic for zero behavioral difference.

### 5. Model selection: same default and override as suggestions

The service uses `OpenRouterSuggestionService.defaultModel` and honors the existing `aiModelOverride` UserDefaults key — one mental model for the user, one settings row. The default (`openai/gpt-5.4-mini`) is vision-capable. If a user overrides to a text-only model, OpenRouter returns an error which maps to `badResponse`; the alert text tells the user to check the model in AI settings.

### 6. Capture UI: `PhotosPicker` + wrapped `UIImagePickerController`, single-sheet phases

- Library: `PhotosPicker` (PhotosUI) — no usage description required, modern multi-select.
- Camera: `UIImagePickerController(sourceType: .camera)` wrapped in `UIViewRepresentable` — the simplest correct camera capture; AVFoundation is overkill for a still photo. Requires `INFOPLIST_KEY_NSCameraUsageDescription` in both Debug and Release pbxproj configs (one of the few pbxproj edits this project ever needs). The camera button is hidden when `UIImagePickerController.isSourceTypeAvailable(.camera)` is false (Simulator), and the flow must remain fully usable via the library path.
- Up to **3 photos** per request; each is downscaled to a max dimension of 1024 px and JPEG-encoded (~0.7 quality) before base64 — keeps the request roughly ≤1.5 MB and image tokens bounded.
- The whole flow is **one sheet** (`PhotoMatchSheet`) with internal phases: capture/review → loading (cancellable, same pattern as suggestion progress) → results. This avoids the chained-sheet `pendingSuggestion`/`onDismiss` dance in `RoutineListView`, which exists only because two separate sheets were involved.
- Results phase lists validated exercises (thumbnail via the existing thumbnail view, localized name, muscle chips, confidence badge) with multi-select; confirming calls an `onAdd: ([Exercise]) -> Void` callback — the exact shape `TemplateEditForm` already handles for `ExerciseMultiPicker`, so the editor integration is one button plus one sheet presentation.

### 7. Test hooks: `-uitest-photo-match <scenario>` + fixture image

Mirroring `-uitest-ai`: scenarios `success` (returns fixed known ids, e.g. gv0025 + gv0043), `error` (throws `.network`), `no-key` (in-memory empty key store). The stub service is swapped via the environment in `gymappApp.init()`. Additionally the sheet exposes a test-only path that loads a bundled fixture image instead of opening camera/`PhotosPicker`, so XCUITest never touches system UI. Unit tests cover the request builder (content-parts shape, schema enum, image part count) and validation (unknown-id dropping, dedupe) with the established `MockURLProtocol` pattern (reading `httpBodyStream`, not `httpBody`).

### 8. Localization

All new user-facing strings ship EN + ES in `Localizable.xcstrings` in the same commit (`LocalizationTests` enumerates keys and fails on missing Spanish values). Views use plain string literals; non-View code uses `String(localized:)`. Accessibility identifiers are hard-coded ASCII (`photo-match-button`, `photo-match-find-button`, `photo-match-result-<id>`, `photo-match-add-button`, …).

## Risks / Trade-offs

- [Full-catalog prompt is ~15–25k tokens per request] → Acceptable: photo match is explicit and infrequent; cost lands on the user's own key with a cheap default model. If it proves expensive, a follow-up can compress the listing (names only) without a contract change.
- [User's model override may not support images] → OpenRouter error maps to `badResponse`; alert copy points at AI settings/model override. No client-side model capability list to maintain (it would rot).
- [Vision matching may return plausible-but-wrong exercises] → Results are suggestions, not auto-adds: the user sees name + muscles + thumbnail and explicitly selects; strict id enum + local validation guarantee only real catalog entries appear.
- [Large images could blow memory or the request size] → Downscale + JPEG-compress before encoding; hard cap of 3 photos enforced in the UI.
- [Camera unavailable in Simulator] → Camera button hidden when unavailable; library path and test fixture path keep development and CI fully functional.
- [Photos are sensitive data leaving the device] → Sent only on explicit user action, never persisted, and disclosed in the AI settings privacy note (spec-level requirement change).

## Open Questions

None blocking. If the default model's vision pricing changes materially, revisit Decision 2's full-catalog choice in favor of a names-only compact listing.
