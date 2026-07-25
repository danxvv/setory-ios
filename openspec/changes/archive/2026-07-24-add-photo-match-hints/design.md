## Context

The photo-match flow (`PhotoMatchSheet` → `PhotoMatchRequestBuilder` → `OpenRouterPhotoMatchService`) sends the whole local catalog as one JSON text part plus up to three JPEG image parts, and constrains the answer with a strict `json_schema` whose `exerciseId` enum is exactly the ids in that listing. The listing is the only thing pinning the model to real exercises — and it is also the only thing the model has to disambiguate a cable stack from a pec deck.

Two facts shape this design:

- The response schema enum is **derived from the payload catalog** (`responseSchema(exerciseIds: payload.catalog.map(\.id))`). Filtering the catalog therefore filters the answer space structurally, not by asking the model nicely.
- `Exercise` already carries `primaryMuscles: [Muscle]`, and `ExerciseFilters` in `ExerciseFilterBar.swift` already defines "filter by muscle" as `primaryMuscles.contains(muscle)`. The library, the pickers, and this feature should agree on what "chest exercise" means.

Constraints: OpenRouter stays the only network dependency and its REST contract is unchanged; photos and now the hints are transient (never persisted); every new UI string needs a Spanish value or `LocalizationTests` fails.

## Goals / Non-Goals

**Goals:**

- Let the user attach one short free-text description and one main-muscle selection to a photo-match request.
- Make a selected muscle *hard*-narrow the answer space by shrinking the catalog listing (and therefore the schema enum), not just soft-hint the prompt.
- Keep both inputs optional, with the no-hints request identical to today's.
- Keep the failure surface unchanged: existing error taxonomy, existing retry, existing no-matches state.

**Non-Goals:**

- Multi-muscle selection or equipment filtering. One muscle is the ask; the design leaves room but does not build it.
- Secondary-muscle matching. A "chest" filter means primary chest, consistent with the library filter.
- Persisting hints across sheet presentations or reusing them in the routine-suggestion flow.
- Matching from a description alone (no photos) — this stays a photo feature.

## Decisions

### 1. Filter the catalog, don't just prompt with the muscle

**Decision:** When `muscle != nil`, `PhotoMatchRequestBuilder.payload` drops every exercise whose `primaryMuscles` does not contain it, *and* the prompt text names the muscle.

**Why:** The schema enum is built from the payload catalog, so filtering makes an off-muscle answer unrepresentable rather than merely discouraged. Naming the muscle in the text as well costs a handful of tokens and tells the model *why* the catalog is small, which keeps it from forcing a bad match out of a thin list.

**Alternative rejected:** Send the full catalog and add "prefer chest exercises" to the prompt. Cheaper to implement, but leaves the failure mode the feature exists to fix — the model can still return a lat pulldown — and forfeits the payload shrink (a single-muscle catalog is typically 5–10% of 1300+ rows, which measurably cuts request size and latency).

**Alternative rejected:** Filter after the response instead. Wastes the round trip and can empty an otherwise useful result list.

### 2. Primary muscles only, reusing the library's definition

**Decision:** Match `ExerciseFilters.apply`'s semantics — `primaryMuscles.contains(muscle)`.

**Why:** Two different meanings of "chest exercises" in one app is a bug the user reports as inconsistency. Including secondary muscles would pull bench-press variants into a "triceps" filter and dilute exactly the narrowing being asked for.

**Note:** Do not extract a shared helper for this one-line predicate — `ExerciseFilters` is a view-layer type carrying search text and equipment; the builder is a pure static over models. Duplicating one `contains` is cheaper than coupling them. If a third caller appears, hoist it onto `Exercise` then.

### 3. Empty filtered catalog blocks the request

**Decision:** If the filter yields zero exercises, the sheet disables the find action and shows an inline localized message pointing at the muscle selection. No request is sent.

**Why:** A strict `json_schema` with an empty `enum` array is invalid and OpenRouter rejects it — the user would get a generic `badResponse` alert for what is really "you picked a muscle nothing in your catalog targets". Reachable in practice only on a store whose catalog was wiped down to custom exercises, but it is a one-line guard against a confusing dead end.

**Alternative rejected:** Silently fall back to the unfiltered catalog. It contradicts the user's explicit selection and produces exactly the wrong-muscle results the feature was added to prevent.

### 4. Description: trimmed, capped, and carried as its own labeled line

**Decision:** Trim whitespace, drop if empty, cap at 200 characters (enforced at the model layer, not just the text field), and emit as a distinct labeled line in the text part — e.g. `User description of the equipment or exercise: <text>` — separate from the catalog JSON and separate from the muscle line.

**Why:** A cap keeps a pasted wall of text from crowding the catalog listing out of the context window. Labeling it separately marks it as *data the user supplied*, not instruction, which is the honest framing for untrusted input.

**Prompt-injection note:** The description is user-authored free text landing in a prompt. The blast radius is bounded by the structured output: the model can only answer with ids from the enum, so the worst case is mis-ranked or empty matches — the user harming their own result. The system prompt gains a line telling the model to treat the description as a hint about the photo and to keep answering only with catalog ids. No further sanitizing is warranted for a single-user, own-API-key flow.

### 5. Hints live on `PhotoMatchRequestPayload`, filtering happens in the builder

**Decision:** `PhotoMatchRequestPayload` gains `userDescription: String?` and `muscle: Muscle?`. `payload(exercises:photos:description:muscle:)` applies the filter and normalizes the description; `requestBody` only reads what the payload already holds.

**Why:** Keeps `PhotoExerciseMatchService` and its stub untouched (the protocol still takes one payload), keeps validation honest (`validExerciseIds` is still `payload.catalog.map(\.id)`, so it automatically reflects the filtered set), and keeps the whole thing unit-testable with no networking — the existing `PhotoMatchRequestBuilderTests` pattern of inspecting the serialized body still applies.

**Note:** `payload(exercises:photos:)`'s two new parameters get defaults (`nil`) so existing call sites and tests compile unchanged.

### 6. UI: description field and muscle menu in the capture phase

**Decision:** Both controls go in the existing capture `Form`, in a section below the photos, above the find action. The muscle control mirrors `ExerciseFilterBar`'s `Menu` (an "Any muscle" reset entry plus `Muscle.allCases`, checkmark on the selection); the description is a single-line `TextField`. Both are disabled while `isMatching`, and both reset with the sheet.

**Why:** Reuses a menu pattern the user already knows from the library and pickers, and reuses the `Muscle.displayName` localization that already exists. Putting them in the capture phase keeps the "attach → describe → find" order literal.

**XCUITest note:** offscreen `Menu` items need `app.swipeUp()` first (see CLAUDE.md); the UI test drives the menu accordingly.

## Risks / Trade-offs

- **A wrong muscle guess now hides the right answer.** Previously a bad hunch cost nothing; now selecting "chest" for a machine that is catalogued under "shoulders" guarantees a miss. → The results phase already offers "Try Other Photos" back to capture with the hints still editable, and the muscle is optional and defaults to unset, so the user opts into the narrowing.
- **Free text in a prompt is untrusted input.** → Bounded by the structured-output enum (decision 4); the model cannot name an exercise that was not sent. Cap and labeling limit the rest.
- **A thin filtered catalog can pressure the model into a low-confidence match.** → The system prompt already permits an empty match list, and confidence tiers are surfaced in the results rows; the muscle line in the prompt tells the model the list is deliberately narrow.
- **Two places now encode "filter by primary muscle."** → Accepted duplication of one predicate (decision 2), with a stated trigger for hoisting it if a third caller appears.
- **Payload shape changes.** → Source-level only; nothing is persisted or versioned, so there is no migration. Rolling this back is deleting the two fields and the UI section.
