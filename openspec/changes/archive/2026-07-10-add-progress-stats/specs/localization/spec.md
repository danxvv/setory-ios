# localization Specification (delta)

## MODIFIED Requirements

### Requirement: Localized user interface
All user-facing text in the app SHALL be resolved through the localization system. The app SHALL support English (`en`, the development language) and Spanish (`es`). When the device language is Spanish, all app-provided text — navigation titles, tab labels, buttons, form labels and placeholders, section headers, footers, and empty states — MUST appear in Spanish. When the device language is unsupported, the app MUST fall back to English.

#### Scenario: Spanish device shows Spanish UI
- **WHEN** the app runs on a device set to Spanish
- **THEN** every screen (logging, set entry, routines list, routine detail, exercises library, exercise detail, exercise edit form, progress tab, exercise progression, tab bar) renders its app-provided text in Spanish

#### Scenario: English device shows English UI
- **WHEN** the app runs on a device set to English
- **THEN** all app-provided text renders in English

#### Scenario: Unsupported language falls back to English
- **WHEN** the app runs on a device set to a language other than English or Spanish
- **THEN** all app-provided text renders in English
