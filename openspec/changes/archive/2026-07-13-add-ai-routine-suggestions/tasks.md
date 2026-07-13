# Tasks: add-ai-routine-suggestions

## 1. Contract types and key storage

- [x] 1.1 Define the suggestion wire types in `Models/`: `SuggestionRequestPayload` (catalog entries with ID/category/muscle raw values, history sessions with dates/exercise IDs/series counts/muscles, optional goal) and `SuggestedRoutine` (name, rationale, items with `exerciseId` + `targetSets`), all `Codable`.
- [x] 1.2 Implement `APIKeyStore` in `Services/`: Keychain-backed (generic password, service = bundle ID) with `read/save/clear`, plus a protocol and an in-memory implementation for tests.
- [x] 1.3 Unit-test `APIKeyStore` semantics through the protocol (save/replace/clear/read round-trip) using the in-memory store, Swift Testing style.

## 2. Prompt building and response parsing (pure logic)

- [x] 2.1 Implement `SuggestionPromptBuilder` (stateless enum, pure statics): builds system prompt (coach role, constraints, device-language instruction), user-message JSON payload from fetched `Exercise` and `WorkoutSession` models (last 10 sessions), and the strict `response_format` JSON schema with the catalog-ID enum.
- [x] 2.2 Implement `SuggestionResponseParser`: decode chat-completion JSON, extract `message.content`, decode `SuggestedRoutine`, validate (drop unknown exercise IDs against local store, clamp `targetSets` to 1–10, dedupe preserving first occurrence, fail on zero valid items), and map error shapes (HTTP error body, embedded `finish_reason == "error"`, malformed JSON) to a typed `SuggestionError`.
- [x] 2.3 Unit tests for builder and parser: payload contents (muscle raw values present, empty-history case, goal forwarding), validation scenarios from the spec, and error mapping from OpenRouter JSON fixtures (401/402/429/mid-stream error).

## 3. OpenRouter client

- [x] 3.1 Define `RoutineSuggestionService` protocol (`suggestRoutine(request:) async throws -> SuggestedRoutine`) and implement `OpenRouterSuggestionService` with `URLSession` async/await: POST `https://openrouter.ai/api/v1/chat/completions`, Bearer key from `APIKeyStore`, model from override-or-default constant, ~60 s timeout, cancellation support.
- [x] 3.2 Implement `StubSuggestionService` (configurable success/failure/delay) and the `-uitest-ai <scenario>` launch-argument wiring in `gymappApp.swift` (stub service + in-memory key store), consistent with existing `-uitest-reset`/`-uitest-seed` handling.
- [x] 3.3 Unit-test `OpenRouterSuggestionService` request assembly and response handling with a `URLProtocol`-based fake (no real network): headers, body shape, model selection, error paths.

## 4. AI settings screen

- [x] 4.1 Build `AISettingsView` (sheet from a gear toolbar button on the Routines tab): masked API key field with save/clear and a "key configured" state that never echoes the key, model-override field showing the default, privacy note. Add accessibility identifiers for UI tests.
- [x] 4.2 Add all settings strings to `Localizable.xcstrings` in English and Spanish.
- [x] 4.3 UI test: open settings, save a key (stub store), verify the suggest entry point unlocks; clear the key, verify it returns to the key-required state.

## 5. Suggest-with-AI flow

- [x] 5.1 Add the "Suggest with AI" toolbar action to the Routines tab: no-key state (explanation + open-settings action, no network), suggestion sheet with optional goal field and Generate button.
- [x] 5.2 Implement the generation flow: progress state with cancel (cancel returns to the sheet with no error), call the injected `RoutineSuggestionService`, map `SuggestionError` cases to localized alerts with Retry (401/402 point to settings).
- [x] 5.3 On success, present the existing template editor pre-filled via `TemplateDraft` (suggested name, exercises, target sets) with the rationale displayed; Save persists a standard `RoutineTemplate`, Cancel discards. Verify muscle coverage derives from local records.
- [x] 5.4 Add all suggest-flow strings to `Localizable.xcstrings` in English and Spanish.

## 6. UI tests and verification

- [x] 6.1 UI tests for the suggest flow with `-uitest-ai`: success scenario (generate → editor prefilled → save → template appears in list), error scenario (localized alert + retry), no-key scenario (settings prompt shown, no editor).
- [x] 6.2 Run the full unit and UI test suites; verify localization completeness for the new keys (both languages) per the existing `LocalizationTests` approach.
- [ ] 6.3 Manual end-to-end check with a real OpenRouter key on device/simulator: generate with and without history, offline behavior, invalid-key behavior. Update `openspec/config.yaml`'s AI-backend note to reflect direct OpenRouter integration.
