# ai-settings Delta Specification

## MODIFIED Requirements

### Requirement: Privacy disclosure
The AI settings screen SHALL display a localized note describing what data is sent to OpenRouter: for routine suggestions, exercise IDs, set counts, muscle-target metadata, session dates, and the optional goal text; for photo exercise matching, the user's photos together with the exercise catalog listing (ids, names, and muscle-target metadata). The note SHALL clarify that requests happen only when the user explicitly asks for a suggestion or a photo match, under the user's own API key, and that photos are not stored by the app.

#### Scenario: Privacy note visible
- **WHEN** the user opens AI settings on a Spanish-language device
- **THEN** the privacy note is shown in Spanish and lists the data categories sent to OpenRouter for both suggestions and photo matching, including that photos are uploaded only on explicit request
