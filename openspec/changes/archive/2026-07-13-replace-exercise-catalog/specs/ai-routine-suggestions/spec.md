# ai-routine-suggestions Specification (Delta)

## MODIFIED Requirements

### Requirement: Suggestion request contract
Suggestions SHALL be obtained from the OpenRouter REST API (`POST https://openrouter.ai/api/v1/chat/completions`, authenticated with the stored key as a Bearer token) — inference never happens on-device. The request MUST use a structured-output response format (strict JSON schema) describing a routine as a name, a rationale, and an ordered list of items each holding a catalog exercise ID and a target set count. The request payload MUST include a bounded, relevance-filtered subset of the exercise catalog — not the full catalog — composed of: exercises from the user's recent workout history, exercises matching goal-relevant muscles when a goal is provided, and a sample spread across muscle groups and equipment for variety, deduplicated and capped at a fixed maximum. Each included exercise carries its ID, category, equipment, and muscle-target metadata (primary and secondary muscles, serialized as the stable `Muscle` raw values). The response schema's exercise-ID constraint MUST be built from the same subset. The payload MUST also include a summary of recent workout history (dates, exercise IDs with series counts, and muscles worked) and the user's goal text when provided. The request MUST instruct the model to respond with user-facing text (name, rationale) in the device language (English or Spanish).

#### Scenario: Payload is bounded at full catalog size
- **WHEN** a suggestion is generated with the full 1,300+ exercise catalog seeded
- **THEN** the request contains no more catalog entries than the fixed maximum, and every entry carries its ID, category, equipment, and muscle raw values

#### Scenario: Recent exercises are always included
- **WHEN** a suggestion is generated for a user with recent workout sessions
- **THEN** every exercise from the recent-history summary appears in the catalog subset sent to the API

#### Scenario: Goal text influences the subset
- **WHEN** the user enters "focus legs, 45 minutes" as the goal and generates
- **THEN** the request payload includes that goal text and the catalog subset includes exercises targeting leg muscles

#### Scenario: No history available
- **WHEN** a suggestion is generated before any workout has been logged
- **THEN** the request is still valid with a sampled catalog subset, indicating the history is empty, and the model is asked for a balanced starter routine
