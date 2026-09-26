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

- A Mac with **Xcode 27** and its **iOS 27 SDK** installed. The instructions below use Xcode 27.0.
- An iPhone or simulator running **iOS 26.5 or later**, including **iOS 27**. The project's minimum deployment target remains 26.5; using iOS 27 does not require raising it.
- An OpenRouter key only if you want to use the optional AI features.

### Run locally

```sh
git clone git@github.com:danxvv/setory-ios.git
cd setory-ios
open Setory.xcodeproj
```

For a simulator, select the **Setory** scheme, choose an iPhone running **iOS 27**, and press **⌘R**. Install the iOS 27 simulator runtime from **Xcode → Settings → Components** if it is missing. For a physical iPhone, follow the Xcode or CLI steps below.

The app, Xcode project, scheme, and Swift module are named **Setory**. The repository is `setory-ios`, and the app's bundle identifier is `danxvv.setory`. There is no package installation or separate backend to start. The exercise catalog is bundled and seeded automatically on launch.

Builds installed under an earlier bundle identifier remain separate apps. Their local workouts, templates, preferences, and API key do not automatically transfer to Setory.

### Install on an iPhone with Xcode 27

1. Open **Setory.xcodeproj** in Xcode 27 and sign in under **Xcode → Settings → Apple Accounts**. A free Personal Team is enough for testing on your own iPhone.
2. Connect your unlocked **iOS 27** iPhone by USB and accept **Trust This Computer**. In Xcode's run-destination menu, choose **Manage Devices** to open [Device Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub) and finish pairing the phone.
3. On the iPhone, enable **Settings → Privacy & Security → Developer Mode**, restart, and confirm. The switch may appear only after pairing begins. See Apple's [Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. Select the blue **Setory** project in the Project navigator, then **TARGETS → Setory → Signing & Capabilities**. Click **Set Up Signing** if offered, select your team, and use `danxvv.setory` as the bundle identifier. Otherwise, enable **Automatically manage signing** and select your team directly. If Apple says that identifier is unavailable to your team, choose a unique personal one, such as `com.yourname.setory`.
5. In the toolbar, select the **Setory** scheme and your **physical iPhone** as the run destination. Let device preparation finish; choose the phone itself rather than a simulator or the generic **Any iOS Device** destination.
6. Choose **Product → Run** (**⌘R**). Xcode builds, signs, installs, and launches Setory. Accept any device-registration, Keychain, or developer-trust prompts needed to complete setup.

After installation, you can open **Setory** from the iPhone's Home Screen. For later updates, run the same project on the same phone with the same bundle identifier and signing team; you do not need to uninstall the app. Apple's [guide to running on physical devices](https://developer.apple.com/documentation/xcode/building-and-running-an-app) covers the signing and device-selection screens.

If the phone is missing or ineligible, check its status in **Device Hub**, unlock it, and verify pairing and Developer Mode. Install any requested iOS platform support in **Xcode → Settings → Components**. For a newer iOS 27 update or beta, use an Xcode version that supports that specific device OS.

With a free Personal Team, provisioning profiles expire after **7 days**, so rebuild and reinstall periodically using either workflow. See Apple's [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account).

### Install on an iPhone from the CLI

Run these commands from the repository root on your Mac using **Xcode 27**. They install on a physical **iOS 27** iPhone and also support devices running the project's minimum iOS 26.5 version.

First complete the account, pairing, Developer Mode, and automatic-signing setup in the [Xcode instructions above](#install-on-an-iphone-with-xcode-27). You can find the selected team's identifier in the Setory target's **Build Settings → Development Team**.

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

If `xcodebuild` reports that it requires Xcode or `devicectl` cannot be found, check `xcode-select -p`. With Xcode installed in its usual location, select it using `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`, then open Xcode to complete any first-launch setup. If the iPhone is missing or listed as ineligible, check pairing, Developer Mode, its iOS version, and whether your installed Xcode supports that version.

### Run tests

Use a dedicated DerivedData directory to avoid interference from Xcode previews. These examples use an **iPhone 18 Pro** simulator with **iOS 27.0**; install that runtime in Xcode's Components settings, or select another installed simulator:

```sh
# Unit tests
xcodebuild test -project Setory.xcodeproj -scheme Setory \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath /tmp/setory-unit-tests \
  -only-testing:SetoryTests

# UI tests: boots the simulator and runs parallel workers
DEVICE="iPhone 18 Pro" DERIVED_DATA=/tmp/setory-ui-tests scripts/uitest.sh
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
