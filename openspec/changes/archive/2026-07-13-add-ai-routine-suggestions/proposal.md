# Proposal: add-ai-routine-suggestions

## Why

The app tracks workout history with rich muscle-target metadata, but composing a balanced next routine is still entirely manual. The domain model (stable exercise IDs, muscle raw values) was designed from the start to feed an AI suggestion service; this change delivers that feature by calling the OpenRouter API directly from the app, superseding the earlier plan of a separate FastAPI backend — the user supplies their own OpenRouter API key, so no server needs to be built or operated.

## What Changes

- New "Suggest with AI" action in the Routines tab that generates a routine template from the user's recent workout history plus an optional free-text goal (e.g. "focus legs, 45 minutes").
- The suggestion is produced by OpenRouter's chat completions endpoint using structured outputs (strict JSON schema), constrained to the bundled catalog's exercise IDs so every suggested item maps to a real `Exercise` record.
- The generated routine opens in the existing template editor as an editable draft; nothing is persisted until the user saves, after which it is a normal `RoutineTemplate`.
- New Settings screen (first in the app) where the user pastes their OpenRouter API key (stored in the Keychain) and can optionally override the model ID; a sensible default model is hardcoded.
- First networking code in the app: a small OpenRouter client behind a protocol, with a stub implementation for unit/UI tests (no network in tests).
- The feature degrades gracefully: without an API key the action explains how to enable it; on network/API errors the user gets a readable, localized error and the rest of the app is unaffected (tracking remains fully offline).
- All new UI strings localized in English and Spanish per the existing localization capability.

## Capabilities

### New Capabilities

- `ai-routine-suggestions`: Generate a suggested routine template from recent workout history and an optional user goal via the OpenRouter API; review and edit the suggestion in the template editor before saving; constrain suggestions to catalog exercises; handle missing-key, network, and malformed-response failures gracefully.
- `ai-settings`: Settings screen for AI configuration — entering/clearing the OpenRouter API key (Keychain-backed, never stored in plaintext preferences) and overriding the default model ID.

### Modified Capabilities

_None — the AI flow reuses the existing template editor and produces standard routine templates; `routine-templates`, `localization`, and other existing requirements are unchanged. New user-facing strings are covered by the existing `localization` requirements._

## Impact

- **New code**: OpenRouter HTTP client (`URLSession`-based, first networking in the app), Keychain-backed key store, suggestion request builder (workout history + catalog + goal → prompt/schema), Settings screen, "Suggest with AI" entry point and loading/error UI in the Routines tab.
- **Reused seams**: `ExerciseHistoryProvider`-style history summarization, `Muscle`/`ExerciseCategory` raw values and exercise IDs as the wire contract, `TemplateDraft` → template editor flow for review/save.
- **Dependencies**: none added — Apple frameworks only (`URLSession`, Security/Keychain). External dependency is the OpenRouter REST API (`POST https://openrouter.ai/api/v1/chat/completions`), treated as an external service defined by its REST contract.
- **Supersedes**: the `openspec/config.yaml` note about a future Python/FastAPI backend — the app now talks to OpenRouter directly with a user-provided key (config to be updated when this change lands).
- **Privacy/cost**: workout history (exercise IDs, set counts, muscles) is sent to OpenRouter under the user's own API key; requests happen only when the user explicitly taps the suggest action.
- **Tests**: unit tests for prompt/schema building, response parsing/validation, and key store; UI tests with a stubbed suggestion client via a launch-argument hook (consistent with `-uitest-reset`/`-uitest-seed`).
