<div align="center">

# Setory

A native iOS workout journal for planning routines, logging training, and tracking progress.

**SwiftUI · SwiftData · iOS 26.5+ · English & Español**

[Get started](#get-started) · [Features](#features) · [Documentation](docs/README.md) · [Development](docs/development.md)

</div>

---

## Features

Core features work offline, with no account or AI key.

| Explore | Train | Review |
| :--- | :--- | :--- |
| Browse 1,324 exercises with instructions and bundled thumbnails. | Log strength sets (reps × kg) or cardio duration. | See completed sessions and per-exercise history. |
| Search in English or Spanish and filter the catalog. | Build reusable templates and apply them as a daily checklist. | Track training frequency, muscle coverage, and personal records. |
| Stream exercise demonstrations, cached after first view. | Save a finished day, or turn a past session into a template. | View progress charts computed from saved workouts. |

### Optional AI features

These require your own [OpenRouter](https://openrouter.ai) API key:

- **Routine suggestions:** proposes a routine from a goal and your recent history.
- **Photo matching:** finds catalog exercises from equipment photos, with optional description and muscle hints.

Results open as an editable draft; nothing is saved until you confirm. Set the key in **Routines → AI Settings**. It is stored in the Keychain. Requests send the relevant training context or selected photos to OpenRouter; see [AI integration](docs/ai.md).

## Usage

1. In **Log**, pick a day and add exercises or apply a template.
2. Record sets as you train. Template items act as a checklist and can be changed.
3. Tap **Finish Day** to save the session and update history and charts.
4. Review results in **Routines** and **Progress**.

> Unsaved daily drafts are lost when the app restarts. Completed days are read-only.

## Get started

### Requirements

- Mac with **Xcode 27** (iOS 27 SDK)
- iPhone or simulator running **iOS 26.5 or later**
- Optional: an OpenRouter key for AI features

### Run in the simulator

```sh
git clone https://github.com/danxvv/setory-ios.git
cd setory-ios
open Setory.xcodeproj
```

Select the **Setory** scheme and an iOS 27 iPhone simulator, then press **⌘R**. If no iOS 27 simulator is listed, install the runtime in **Xcode → Settings → Components**. There are no packages to install and no backend; the exercise catalog is bundled and seeded on first launch.

### Run on an iPhone (Xcode)

1. Sign in under **Xcode → Settings → Apple Accounts**. A free Personal Team works.
2. Connect the iPhone by USB, unlock it, and tap **Trust**. Open [Device Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub) (run-destination menu → **Manage Devices…**) and complete pairing. On iOS 27 you can instead pair over Wi-Fi via **+ → Pair Nearby Device…**.
3. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode** and tap **Restart**. After restarting, tap **Enable** and enter your passcode. The switch only appears once pairing has started. See [Enabling Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. In Xcode, select the **Setory** project → **TARGETS → Setory → Signing & Capabilities**. Keep **Automatically manage signing** on, choose your team, and set a **Bundle Identifier** unique to you, such as `com.yourname.setory`. (`danxvv.setory` belongs to the maintainer's team and won't work for other accounts.)
5. Choose your iPhone as the run destination (not a simulator or **Any iOS Device**) and press **⌘R**.
6. If launch fails because the developer isn't trusted, [trust your certificate](#trust-the-developer-certificate) and press **⌘R** again.

To update, run again with the same team and bundle ID. Installing over the existing app keeps its data. See [Running your app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

#### Trust the developer certificate

Free Personal Team builds must be trusted once on the device:

1. On the iPhone, open **Settings → General → VPN & Device Management**. (No VPN is involved.)
2. Under **Developer App**, tap your Apple Account.
3. Tap **Trust "Apple Development: …"**, then **Trust**.

This is separate from Developer Mode. If no **Developer App** entry appears, the install didn't complete; run again from Xcode.

### Run on an iPhone (command line)

Complete steps 1–3 above first. The build below sets the team and bundle ID on the command line, so the project file is not modified.

Find your iPhone's UDID and your Team ID:

```sh
# Use the "id" listed under platform:iOS (not iOS Simulator)
xcodebuild -project Setory.xcodeproj -scheme Setory -showdestinations

# Team ID is the 10-character "OU=" value on your Apple Development certificate
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject
```

Build, install, and launch:

```sh
DEVICE_UDID="YOUR_IPHONE_UDID"
TEAM_ID="YOUR_TEAM_ID"
BUNDLE_ID="com.yourname.setory"
BUILD_DIR="/tmp/setory-iphone"

xcodebuild build \
  -project Setory.xcodeproj \
  -scheme Setory \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"

xcrun devicectl device install app --device "$DEVICE_UDID" \
  "$BUILD_DIR/Build/Products/Debug-iphoneos/Setory.app"

xcrun devicectl device process launch --device "$DEVICE_UDID" "$BUNDLE_ID"
```

Keep the phone unlocked during install and launch. If launch is blocked, [trust the certificate](#trust-the-developer-certificate) and rerun the launch command. Changing `BUNDLE_ID` later installs a separate app with separate data.

**Troubleshooting**

- *`xcodebuild` requires Xcode* or *`devicectl` not found*: run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.
- *Device missing or ineligible*: check pairing and Developer Mode in Device Hub, and confirm your Xcode version supports the phone's iOS version.

### Free Personal Team: rebuild every 7 days

Free provisioning profiles [expire after 7 days](https://developer.apple.com/help/account/basics/about-your-developer-account), after which Setory won't launch. Re-trusting the certificate doesn't fix this; you need a fresh build:

- **Xcode:** connect the phone and press **⌘R**.
- **CLI:** rerun the `xcodebuild build` command, then install. Reinstalling the old `.app` won't work.

Use the same team and bundle ID, and don't uninstall first, so your workouts are kept.

### Run tests

Use a dedicated DerivedData directory, since Xcode Previews can overwrite the default app bundle and cause launch crashes.

```sh
# Unit tests
xcodebuild test -project Setory.xcodeproj -scheme Setory \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath /tmp/setory-unit-tests \
  -only-testing:SetoryTests

# UI tests (boots the simulator, runs parallel workers)
DEVICE="iPhone 18 Pro" DERIVED_DATA=/tmp/setory-ui-tests scripts/uitest.sh
```

`scripts/uitest.sh` accepts `DEVICE` (default `iPhone 17 Pro`), `WORKERS` (default 6), and `DERIVED_DATA`. See [Development and testing](docs/development.md) for focused runs, fixtures, and launch options.

## Architecture

SwiftUI for UI, SwiftData for persistence, Swift Testing for unit tests, XCUITest for UI tests.

```text
Setory/
├── App/             Entry point, navigation, model container
├── Domain/          Persisted entities, drafts, vocabulary, statistics
├── Persistence/     Catalog seeding and write stores
├── Features/        Logging, exercises, routines, progress, settings
├── AI/              Shared OpenRouter client, suggestions, photo matching
├── Media/           Thumbnail and animation caching
├── DesignSystem/    Theme and shared components
├── Resources/       Bundled catalog and thumbnails
└── TestSupport/     Debug-only fixtures and launch overrides
```

Views delegate database writes to persistence stores. Both AI features share one HTTP client with separate request builders and response parsers. Statistics live in `Domain/` and are independent of the UI.

## Documentation

| Guide | Contents |
| :--- | :--- |
| [Architecture](docs/architecture.md) | Startup, navigation, layers, dependencies |
| [Screens and flows](docs/screens.md) | Screen behavior, validation, state transitions |
| [Data and statistics](docs/data-and-statistics.md) | Models, saving, chart calculations, records |
| [AI integration](docs/ai.md) | Credentials, request contents, validation, errors |
| [Catalog, media, and localization](docs/catalog-media-localization.md) | Exercise data, translations, caching, attribution |
| [Development and testing](docs/development.md) | Build setup, test workflows, maintenance |
| [Source reference](docs/modules.md) | Per-file responsibilities |

Design specs and archived changes are in [openspec/](openspec).

## Data and privacy

All workouts and templates are stored on-device. There is no account, cloud sync, or export. Everything works offline except uncached animations and AI features.

## Credits

Exercise data and instructions come from **hasaneyldrm/exercises-dataset** (MIT; license reproduced in the app's About screen). Exercise images and animations are © Gym visual, redistributed at 180×180 with permission under separate terms. The dataset license does not cover the app or the media.

See [`AboutView.swift`](Setory/Features/Settings/AboutView.swift) for the shipped attribution and [catalog tooling](tools/catalog/README.md) for the import workflow.