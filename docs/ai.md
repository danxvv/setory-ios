# AI integration

[Documentation index](README.md)

## Shared infrastructure

The app sends requests directly to OpenRouter using the user's API key; no application proxy backend appears in this repository. [OpenRouterClient](../Setory/AI/Shared/OpenRouterClient.swift) owns the POST to `https://openrouter.ai/api/v1/chat/completions`, bearer authorization, JSON content type, and a 60-second request timeout.

The key lives in a Keychain generic-password item whose service is the bundle identifier and account is `openrouter-api-key`. A missing/empty key prevents transport from starting. The model comes from `AIModelPreference`: the trimmed `aiModelOverride` preference, or the checked-in default `openai/gpt-5.4-mini`. This is the app's configured default, not a claim about current provider availability or pricing. Both features use the same setting.

[AIEnvironment](../Setory/AI/Shared/AIEnvironment.swift) exposes protocol-backed dependencies to views. Tests can replace key storage and both services. The normal suggestion/photo services each combine their own builder and parser with the shared client.

## Routine suggestion

```text
Routines → SuggestRoutineSheet → SuggestionFlow
  → fetch exercises and latest sessions → SuggestionPromptBuilder
  → OpenRouterSuggestionService → OpenRouterClient
  → SuggestionResponseParser → resolve local exercise records
  → TemplateEditForm review → user Save → TemplateStore
```

The optional goal is trimmed; blank becomes nil. The request summarizes up to ten latest saved sessions with dates, exercise IDs, set counts, and worked muscles. It includes at most 200 catalog entries containing IDs, category, equipment, and primary/secondary muscles. Exercise names, repetitions, weights, and durations are not included in the suggestion catalog/history payload.

For a large catalog, selection first includes exercises from recent history subject to the total cap, then English/Spanish goal-keyword muscle matches up to a three-quarter budget threshold, then samples remaining primary-muscle buckets round-robin. Candidate ordering and final payload ordering use stable IDs. A catalog already within the cap is included whole.

The prompt asks for 3–8 exercises, balanced against history and the goal. The strict response schema contains `name`, `rationale`, and `items`, with allowed exercise IDs and target sets 1–10. The 3–8 count is a prompt instruction: the schema and parser do not enforce that exact range.

Client validation drops unknown IDs, keeps the first duplicate occurrence, and clamps targets to 1–10. No remaining valid exercises produces `emptySuggestion`. The flow resolves accepted IDs to local `Exercise` objects, creates a `TemplateDraft`, and hands it to the review editor with the rationale. Generation itself does not write a template.

Name and rationale are requested in Spanish when the language code starts with `es`, otherwise English. Catalog IDs and raw taxonomy values remain language-independent.

## Photo matching

```text
Template editor → PhotoMatchSheet capture → PhotoMatchFlow
  → preprocess photos → filter catalog and normalize hints
  → OpenRouterPhotoMatchService → shared client → response parser
  → local exercise matches → user selection → append to template draft
```

The sheet accepts up to three photos from the camera or system picker. [PhotoPreprocessor](../Setory/AI/PhotoMatch/PhotoPreprocessor.swift) downsizes images above its 1024 longest-edge size budget, preserves aspect ratio, and JPEG-encodes at quality 0.7. The request embeds JPEG bytes as base64 data URLs.

The description is trimmed, omitted if blank, and capped at 200 characters. An optional muscle filters the catalog by **primary** muscle. Without that filter the photo request includes the full catalog, unlike suggestions' 200-entry cap. Entries include ID, canonical stored name, equipment, and primary muscles, ordered by ID. For edited exercises the stored name may be user text rather than English.

A selected muscle with no matching exercises disables sending; the flow checks the catalog again before transport. At least one encodable image is required. The prompt/schema requests up to ten matches with exercise ID and `high`, `medium`, or `low` confidence. The parser removes unknown IDs and duplicates while retaining response order; it does not separately truncate a response to ten.

An empty match list is a valid no-recognition result. Returned names, media, and muscle labels come from local records. Results begin unselected; the user chooses exercises and taps Add to append them to the template draft. Returning to capture preserves photos and hints for another attempt.

Photos and hints are transient in app state and are not written to its database or image cache. They are transmitted to OpenRouter on request; the app implementation does not establish the remote provider's retention behavior.

## State, cancellation, and failure

`SuggestionFlow` tracks generation and error state. `PhotoMatchFlow` additionally tracks capture/results phase and muscle-match count. Both own cancellable tasks and expose static async operations for unit tests. Recognized cancellation exits without an error alert. `AIFlowScaffold` provides shared missing-key, loading, and failure UI. There is no automatic retry loop; recovery is user-driven.

| Condition | Mapping / UI recovery |
| --- | --- |
| Missing API key | `missingAPIKey`; configure settings |
| HTTP 401 | `invalidKey`; settings |
| HTTP 402 | `insufficientCredits`; settings |
| HTTP 429 | `rateLimited`; retry |
| Other non-2xx, malformed JSON, missing content, or embedded provider error | `badResponse`; retry |
| Transport failure | `network`; retry |
| Suggestion has no usable exercises | `emptySuggestion`; retry |
| Valid empty photo matches | Results empty state, not an error |

`ChatCompletionResponse` validates the outer completion envelope, including provider errors inside successful HTTP responses, then decodes the assistant content as structured JSON. Feature parsers apply ID and domain validation afterward.

## Contract maintenance

Request-body fixtures live in [SetoryTests/Fixtures](../SetoryTests/Fixtures). Changes to JSON field names, taxonomy raw values, prompts, schema, or model selection can affect the contract. Review builder/parser/service tests together. `UPDATE_REQUEST_FIXTURES=1` intentionally rewrites golden bodies through the fixture test harness; use it only when accepting a deliberate contract change.
