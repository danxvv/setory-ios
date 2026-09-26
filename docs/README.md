# Setory documentation

`Setory` is an iOS workout tracker built with SwiftUI and SwiftData. It combines an exercise library, daily set logging, reusable routine templates, workout history, progress charts, and optional AI assistance through OpenRouter.

This documentation describes the checked-in implementation as inspected on September 7, 2026. Source links point to the implementation; archived OpenSpec proposals describe earlier decisions and can differ from current code.

## Reading guide

| Document | What it explains |
| --- | --- |
| [Architecture](architecture.md) | Startup, layers, dependencies, navigation, and write boundaries |
| [Screens and flows](screens.md) | Each screen's purpose, state, actions, validation, and transitions |
| [Data and statistics](data-and-statistics.md) | Persisted models, transient drafts, saving, and chart calculations |
| [AI integration](ai.md) | Suggestions, photo matching, request contents, validation, and errors |
| [Catalog, media, and localization](catalog-media-localization.md) | Bundled data, upgrades, translations, animations, and attribution |
| [Development and testing](development.md) | Project setup, test entry points, fixtures, and maintenance guidance |
| [Source-file reference](modules.md) | Responsibilities of every application Swift file and supporting directories |

## How the app works

1. The app opens a local database and seeds or updates its bundled exercise catalog.
2. In **Log**, choose a day and add sets manually or use a template as a checklist.
3. **Finish Day** saves the sets as that day's workout session.
4. **Routines** shows reusable templates and completed sessions. A completed session can become a new template.
5. **Exercises** provides searchable instructions, demonstrations, editable exercise information, and exercise history.
6. **Progress** calculates training frequency, muscle coverage, and exercise records from saved sets.
7. Optionally configure an OpenRouter key in **Routines → AI Settings** to request a routine suggestion or identify exercises from photos inside the template editor.

## Important terminology

| Term | Meaning |
| --- | --- |
| Exercise | A catalog record, with a stable ID, category, muscles, instructions, and optional media |
| Set / series | One recorded effort: repetitions and optional kilograms, or cardio duration |
| Draft | Unsaved input held in view state |
| Day plan | A temporary checklist made from a template for one selected date |
| Template | A persisted, named list of exercises and target set counts |
| Session / saved routine | The actual sets saved for a calendar day |

Templates and sessions are independent records. Applying a template does not log sets. Completing fewer or more sets than planned is allowed. Only sets confirmed in the logging sheet and then saved with **Finish Day** contribute to history and charts.

Daily drafts and day plans survive switching dates while the logging view remains alive, but are not restored after an app restart. Completed days are read-only in the current UI. The inspected code contains no workout cloud-sync, account sign-in, or export flow. Core local features do not require an AI key; downloading an uncached animation and using AI require a network connection.
