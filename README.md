<div align="center">

# Setory

### Every set tells a story.

A native iOS workout journal for planning routines, logging training,<br>
and seeing your progress—one session at a time.

**SwiftUI · SwiftData · iOS 26.5+ · English & Español**

[Get started](#get-started) · [Features](#built-for-your-training) · [Documentation](docs/README.md) · [Development](docs/development.md)

</div>

---

## Built for your training

Setory brings your exercise library, daily workout log, reusable routines, and progress charts together in one app. Core training features work locally without an account or an AI key.

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
git clone git@github.com:danxvv/setory-ios.git
cd setory-ios
open Setory.xcodeproj
```

Select the **Setory** scheme, choose an available simulator, and run. For a physical device, configure your signing team in Xcode.

The app, Xcode project, scheme, and Swift module are named **Setory**. The repository is `setory-ios`, and the app's bundle identifier is `danxvv.setory`. There is no package installation or separate backend to start. The exercise catalog is bundled and seeded automatically on launch.

Builds installed under an earlier bundle identifier remain separate apps. Their local workouts, templates, preferences, and API key do not automatically transfer to Setory.

### Install on an iPhone from the CLI

Run these commands from the repository root on your Mac. You need the full Xcode installation and a physical iPhone running **iOS 26.5 or later**.

**Prepare signing and the phone once:**

1. Sign in to your Apple Account in **Xcode → Settings → Apple Accounts** (called **Accounts** in some versions). A free Personal Team can install apps on your own device; a paid membership is not required for this workflow.
2. Connect the unlocked iPhone by USB, accept **Trust This Computer**, and let Xcode finish pairing it. Enable **Settings → Privacy & Security → Developer Mode** on the iPhone, then restart and confirm when prompted. The option may appear only after pairing starts. See Apple's [Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
3. In the **Setory** target's **Signing & Capabilities**, select your team and enable **Automatically manage signing**. You can find the selected team's identifier in **Build Settings → Development Team**. See Apple's [device signing setup](https://developer.apple.com/documentation/xcode/building-and-running-an-app).

**Keep the bundle identifier `danxvv.setory` if your signing team can register or already owns it.** Installing through the CLI does not require changing it. If Xcode reports that the identifier is unavailable to your team, use a unique personal value such as `com.yourname.setory` in `SETORY_BUNDLE_ID` below. This overrides the identifier for that build; the app still displays **Setory**. Keep the chosen identifier and signing team stable for later updates. Changing the bundle identifier creates a separate app with separate local data. See Apple's [bundle identifier guidance](https://developer.apple.com/documentation/xcode/changing-the-bundle-identifier).

Find the connected phone:

```sh
xcrun devicectl list devices
xcodebuild -project Setory.xcodeproj -scheme Setory -showdestinations
```

From `xcodebuild`'s destinations, copy the `id` for your physical iPhone under **platform:iOS**, not an iOS Simulator. Use that hardware UDID for both building and installing; it is different from the app's bundle identifier and your signing Team ID.

Replace the two placeholders below, then build a signed app:

```sh
SETORY_DEVICE_UDID="YOUR_IPHONE_UDID"
SETORY_TEAM_ID="YOUR_TEAM_ID"
SETORY_BUNDLE_ID="danxvv.setory"
SETORY_BUILD_DIR="/tmp/setory-iphone"

xcodebuild build \
  -project Setory.xcodeproj \
  -scheme Setory \
  -configuration Debug \
  -destination "platform=iOS,id=$SETORY_DEVICE_UDID" \
  -derivedDataPath "$SETORY_BUILD_DIR" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$SETORY_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$SETORY_BUNDLE_ID"
```

The provisioning flags let Xcode create or update signing assets and register the destination device using the account configured in Xcode. The command-line signing values apply to this build without editing the project file.

After the build succeeds, install and launch in the **same terminal session**:

```sh
xcrun devicectl device install app \
  --device "$SETORY_DEVICE_UDID" \
  "$SETORY_BUILD_DIR/Build/Products/Debug-iphoneos/Setory.app"

xcrun devicectl device process launch \
  --device "$SETORY_DEVICE_UDID" \
  "$SETORY_BUNDLE_ID"
```

Keep the phone unlocked during installation and launch. If iOS requests developer trust, follow its instructions in **Settings → General → VPN & Device Management**. To install an updated build, repeat the build and install commands with the same identifiers; there is no need to uninstall the app first.

With a free Personal Team, provisioning profiles expire after **7 days**, so you need to rebuild and reinstall periodically. See Apple's [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account).

If `xcodebuild` reports that it requires Xcode or `devicectl` cannot be found, check `xcode-select -p`. With Xcode installed in its usual location, select it using `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`, then open Xcode to complete any first-launch setup. If the iPhone is missing or listed as ineligible, check pairing, Developer Mode, its iOS version, and whether your installed Xcode supports that version.

### Run tests

Use a dedicated DerivedData directory to avoid interference from Xcode previews:

```sh
# Unit tests
xcodebuild test -project Setory.xcodeproj -scheme Setory \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/setory-unit-tests \
  -only-testing:SetoryTests

# UI tests: boots the simulator and runs parallel workers
DERIVED_DATA=/tmp/setory-ui-tests scripts/uitest.sh
```

The UI runner accepts `DEVICE`, `WORKERS`, and `DERIVED_DATA` overrides. See [development and testing](docs/development.md) for focused runs, test fixtures, and launch options.

## Under the hood

The app uses **SwiftUI** for its interface, **SwiftData** for local persistence, **Swift Testing** for unit tests, and **XCUITest** for UI flows.

```text
Setory/
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

See [AboutView.swift](Setory/Features/Settings/AboutView.swift) for the shipped attribution and [catalog tooling](tools/catalog/README.md) for the import workflow. The dataset license does not grant rights to the application or exercise media.
