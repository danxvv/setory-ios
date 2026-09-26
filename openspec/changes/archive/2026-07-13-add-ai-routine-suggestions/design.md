# Design: add-ai-routine-suggestions

## Context

The app is 100% offline today: SwiftData persistence, no networking layer, no settings screen, no secret storage. The domain model was deliberately shaped for this feature — stable kebab-case exercise IDs, `Muscle`/`ExerciseCategory` raw values documented as serialization keys for the AI contract, and pure history providers (`ExerciseHistoryProvider`, `ProgressStatsProvider`).

The original project context planned a separate Python/FastAPI backend wrapping OpenRouter. Per the user's decision, the app now calls the OpenRouter REST API directly with a user-provided API key (BYOK). OpenRouter is the external service, defined by its REST contract:

- `POST https://openrouter.ai/api/v1/chat/completions` with `Authorization: Bearer <key>`, OpenAI-compatible body.
- Structured outputs via `response_format: {"type": "json_schema", "json_schema": {"name", "strict": true, "schema"}}` force the response `message.content` to be JSON matching our schema.
- Errors surface as HTTP error statuses with an `error` object, and can also appear embedded in a 200 response (`choices[0].finish_reason == "error"` with a `choices[0].error` object) — both paths must be handled.

## Goals / Non-Goals

**Goals:**
- "Suggest with AI" in the Routines tab: recent history + optional free-text goal → suggested routine, reviewed in the existing template editor, saved as a normal `RoutineTemplate`.
- Suggestions constrained to bundled-catalog exercise IDs; invalid IDs never reach the UI.
- Keychain-backed API key entry and model-ID override in a new Settings surface.
- Deterministic stubbing for unit and UI tests; no network in any test.
- Graceful degradation: missing key, network failure, or malformed response never affects tracking features.

**Non-Goals:**
- No streaming responses (a routine is one small JSON object; single response is simpler and works with structured outputs).
- No "suggest today's plan" entry point on the Log tab (possible follow-up reusing the same client).
- No fetching of OpenRouter's model list; the model is a hardcoded default plus a free-text override.
- No AI-created exercises outside the catalog; no custom-exercise awareness beyond what is in the local store.
- No load/progression recommendations (weights/reps are not sent; only exercises, set counts, muscles, and dates).
- No proxy backend; if one is ever built, only the client's base URL/auth wiring changes.

## Decisions

### D1: Direct OpenRouter calls with user-provided key (BYOK)
The app calls OpenRouter directly; the user pastes their own API key in Settings. Feature is hidden-but-discoverable without a key (the suggest action explains how to enable it).
- *Alternative — FastAPI proxy backend (original plan)*: rejected for now; requires building/operating a server and an auth story. The client is a thin protocol, so swapping to a proxy later is contained.
- *Alternative — embedded shared key*: rejected; keys in app binaries are extractable and the developer would pay for all usage.

### D2: Request/response contract via structured outputs
One non-streaming chat completion per suggestion:
- **System prompt**: role ("expert strength coach"), the task, constraints (only listed exercise IDs, 3–8 exercises, `targetSets` 1–10, balance against recent muscle coverage), and the response language (device language, so the rationale/name arrive in en/es).
- **User message**: compact JSON payload — the exercise catalog (id, category, primaryMuscles, secondaryMuscles — 40 entries, small), recent history (last 10 sessions: date, exercise IDs with series counts, muscles worked), and the optional goal text.
- **`response_format`**: strict JSON schema — `{ name: string, rationale: string, items: [{ exerciseId: string(enum of catalog IDs), targetSets: integer 1–10 }] (minItems 1) }`.
- **Client-side validation is the real gate**: not every model enforces strict schemas, so the parser drops items with unknown exercise IDs, clamps `targetSets` to 1–10, dedupes repeated exercises, and fails with a typed error if no valid items remain. Muscle metadata for the accepted items comes from the local `Exercise` records, never from the model.
- *Alternative — free-text response parsed heuristically*: rejected; structured outputs exist precisely for this.

### D3: Client architecture follows existing service conventions
- `protocol RoutineSuggestionService` with one async method: `suggestRoutine(request:) async throws -> SuggestedRoutine`. Live implementation `OpenRouterSuggestionService` uses `URLSession` (async/await, ~60 s timeout); `StubSuggestionService` returns canned success/failure for tests.
- Injected via default parameter (the `CatalogSeeder.seed(context:source:)` pattern), not a DI container.
- Prompt building and response parsing are pure static functions on stateless enums (`SuggestionPromptBuilder`, `SuggestionResponseParser`) so they unit-test without networking, matching `TemplateNameSuggester`/`ExerciseHistoryProvider` style.
- Typed error enum (`SuggestionError`): `.missingAPIKey`, `.network`, `.rateLimited`, `.invalidKey`, `.badResponse`, `.emptySuggestion` — each mapped to a localized message.

### D4: Secrets and preferences
- API key in the Keychain (`kSecClassGenericPassword`, service = bundle ID, account = `openrouter-api-key`) behind a tiny `APIKeyStore` wrapper; never in `UserDefaults`, never logged.
- Model override in `@AppStorage` (not a secret). Default model is a single constant (a cheap, structured-outputs-capable model — verify the current best pick on openrouter.ai at implementation time, e.g. an `openai/*-mini`-class model); blank override = default.

### D5: Settings surface = sheet from the Routines tab toolbar
A gear toolbar button on the Routines tab presents a Settings sheet (`Form`: secure key field with save/clear, model-ID field, short privacy note about what is sent). The suggest flow's "no key" state deep-links to it.
- *Alternative — fifth Settings tab*: rejected as heavy for two fields; easy to promote later.

### D6: Suggest flow UX
Sparkle "Suggest with AI" button in the Routines tab toolbar/list → sheet: optional goal text field + Generate → loading (cancellable) → on success, present the existing template editor pre-filled via a `TemplateDraft` (suggested name, items with target sets; rationale shown above the form) → user edits/saves normally; Cancel discards everything. On failure, localized error with Retry. Nothing persists until the editor's Save.

### D7: Test hooks
- Unit tests (Swift Testing): prompt payload building from seeded models, parser validation (unknown IDs, clamping, empty), `APIKeyStore` round-trip, error mapping from OpenRouter error JSON fixtures (HTTP error body and embedded `finish_reason == "error"` case).
- UI tests: new launch argument `-uitest-ai <scenario>` (`success`, `error`, `no-key`) wires `StubSuggestionService` and a non-Keychain in-memory key store, consistent with `-uitest-reset`/`-uitest-seed` handling in `SetoryApp.swift`.

## Risks / Trade-offs

- [Model ignores the schema or hallucinates IDs] → client-side validation (D2) is authoritative; worst case is a typed `.emptySuggestion` error with Retry, never a corrupt template.
- [User's key is invalid/out of credits] → map 401/402/429 to specific localized messages pointing at Settings.
- [Default model is deprecated on OpenRouter] → model ID is one constant plus a user-editable override; no app update strictly required for users.
- [Privacy: history leaves the device] → only IDs, set counts, muscles, and dates are sent (no weights, no personal data); a privacy note sits in Settings; requests happen only on explicit user action, under the user's own key.
- [Goal text is user-controlled prompt input] → low stakes: output is schema-constrained and ID-validated; worst case is a poor suggestion the user can discard.
- [First networking code in the app] → kept to one small client behind a protocol; no third-party dependencies; all other features remain offline.
- [Config drift] → `openspec/config.yaml` still describes the FastAPI-backend plan; update it when this change is archived.
