<div align="center">

# Setwise

### Every set tells a story.

A native iOS workout journal for planning routines, logging training,<br>
and seeing your progress—one session at a time.

**SwiftUI · SwiftData · iOS 26.5+ · English & Español**

[Get started](#get-started) · [Features](#built-for-your-training) · [Documentation](docs/README.md) · [Development](docs/development.md)

</div>

---

## Built for your training

Setwise brings your exercise library, daily workout log, reusable routines, and progress charts together in one app. Core training features work locally without an account or an AI key.

| Explore | Train | Reflect |
| :--- | :--- | :--- |
| Browse **1,324 exercises** with instructions and bundled thumbnails. | Record strength sets with repetitions and kilograms, or cardio duration. | Review completed sessions and individual exercise history. |
| Search in English or Spanish and filter the catalog. | Build reusable templates and apply them as a daily checklist. | Follow training frequency, muscle coverage, and exercise records. |
| Watch exercise demonstrations downloaded on demand. | Save a completed day or turn a past session into a template. | See progress charts calculated from your saved workouts. |

### A little help when you want it

Optional AI tools use your own OpenRouter key:

- **Routine suggestions** use a goal and recent training history to propose a routine you can review and edit.
- **Photo matching** helps find catalog exercises from equipment photos, with optional description and muscle hints.

Suggestions and photo matches enter a draft for your review before you save them. Configure the key in **Routines → AI Settings**; it is stored in the device Keychain. AI requests send the relevant context or selected photos to OpenRouter. See [AI integration](docs/ai.md) for request details.

## From plan to progress

1. **Pick a day** in Log and choose exercises, or apply a saved template.
2. **Record your sets** as you train. Templates act as a checklist; you can adjust the workout as you go.
3. **Tap Finish Day** to save the session and update your history and charts.
4. **Review and repeat** in Routines and Progress.

> Daily drafts are temporary and are not restored after restarting the app. Saved workouts persist locally. Completed days are currently read-only in the UI.

## Get started

### Requirements

- A Mac with Xcode and an iOS SDK supporting the project's **iOS 26.5** deployment target.
- An iOS 26.5+ simulator or device. The repository's documented development setup uses **Xcode 26.6** and an **iPhone 17 Pro** simulator.
- An OpenRouter key only if you want to use the optional AI features.

### Run locally

```sh
git clone git@github.com:danxvv/setwise-ios.git
cd setwise-ios
open gymapp.xcodeproj
```

Select the **gymapp** scheme, choose an available simulator, and run. For a physical device, configure your signing team in Xcode.

The Xcode project and targets retain their original `gymapp` names. There is no package installation or separate backend to start. The exercise catalog is bundled and seeded automatically on launch.

### Run tests

Use a dedicated DerivedData directory to avoid interference from Xcode previews:

```sh
# Unit tests
xcodebuild test -project gymapp.xcodeproj -scheme gymapp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/setwise-unit-tests \
  -only-testing:gymappTests

# UI tests: boots the simulator and runs parallel workers
DERIVED_DATA=/tmp/setwise-ui-tests scripts/uitest.sh
```

The UI runner accepts `DEVICE`, `WORKERS`, and `DERIVED_DATA` overrides. See [development and testing](docs/development.md) for focused runs, test fixtures, and launch options.

## Under the hood

The app uses **SwiftUI** for its interface, **SwiftData** for local persistence, **Swift Testing** for unit tests, and **XCUITest** for UI flows.

```text
gymapp/
├── App/             App entry point, navigation, and model container
├── Domain/          Persisted entities, drafts, vocabulary, and statistics
├── Persistence/     Catalog seeding and dedicated write stores
├── Features/        Logging, exercises, routines, progress, and settings
├── AI/              Shared transport, routine suggestions, and photo matching
├── Media/           Exercise thumbnails and animation caching
├── DesignSystem/    Theme and shared interface components
├── Resources/       Bundled exercise catalog and thumbnails
└── TestSupport/     Debug-only fixtures and launch overrides
```

Feature views delegate database writes to persistence stores. Both AI features share a single transport, with separate request builders and response parsers. Domain statistics remain independent of screen presentation.

## Documentation

| Guide | What's inside |
| :--- | :--- |
| [Architecture](docs/architecture.md) | Startup, navigation, layers, and dependency boundaries |
| [Screens and flows](docs/screens.md) | Screen behavior, validation, and state transitions |
| [Data and statistics](docs/data-and-statistics.md) | Models, saving, chart calculations, and records |
| [AI integration](docs/ai.md) | Credentials, request contents, validation, and failures |
| [Catalog, media, and localization](docs/catalog-media-localization.md) | Exercise data, translations, caching, and attribution |
| [Development and testing](docs/development.md) | Build setup, test workflows, and maintenance |
| [Source reference](docs/modules.md) | Responsibilities of application files |

Design specifications and archived changes live in [openspec/](openspec).

## Data and connectivity

Workouts and templates are stored on the device. The current app has no account sign-in, workout cloud sync, or export flow. The bundled exercise library and core tracking work offline; uncached animations and AI features need a network connection.

## Credits

Exercise data and instruction text are sourced from **hasaneyldrm/exercises-dataset**, with its MIT license reproduced in the app's About screen. Exercise images and animations are **© Gym visual** and have separate reuse terms; the app records permission for redistribution at 180×180 resolution.

See [AboutView.swift](gymapp/Features/Settings/AboutView.swift) for the shipped attribution and [catalog tooling](tools/catalog/README.md) for the import workflow. The dataset license does not grant rights to the application or exercise media.
