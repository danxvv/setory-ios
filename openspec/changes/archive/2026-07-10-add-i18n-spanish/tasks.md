# Tasks: add-i18n-spanish

## 1. Localization infrastructure

- [x] 1.1 Add `es` to `knownRegions` in `Setory.xcodeproj/project.pbxproj`
- [x] 1.2 Create `Setory/Localizable.xcstrings` with `en` as source language and `es` as a target (synchronized file group picks it up automatically)
- [x] 1.3 Build the app target so Xcode auto-extracts the SwiftUI `LocalizedStringKey` literals into the catalog; confirm the ~30 view-layer strings from `ContentView`, `SetEntrySheet`, `RoutineListView`, `RoutineDetailView`, `RootTabView` appear as keys (verified via emitted `.stringsdata`; CLI builds don't write back into the source catalog, so keys are authored in the catalog from the extracted inventory)

## 2. Externalize non-view strings

- [x] 2.1 Convert `DraftSeries.summary` components to `String(localized:)` with interpolated values; define plural variants in the catalog for reps ("1 rep"/"%lld reps") and minutes, keeping "kg" value formatting locale-aware
- [x] 2.2 Convert the 16 `Muscle.displayName` cases to `String(localized:)` (raw values stay untouched as serialization keys)
- [x] 2.3 Convert the `"Exercise"` fallback name (used in `ContentView` and `RoutineDetailView`) to a localized string
- [x] 2.4 Convert the `"workout saved"` accessibility value in `MonthCalendarView` to a localized string; verify `accessibilityIdentifier("day-…")` stays a plain literal
- [x] 2.5 Convert the `"%lld series"` count on `RoutineListView` to a plural-aware localized string (already a `LocalizedStringKey` interpolation extracted as `%lld series`; plural variants defined in the catalog)

## 3. Exercise display-name localization

- [x] 3.1 Add a computed `localizedName` to `Exercise` that resolves `Bundle.main.localizedString(forKey: "exercise.\(id)", value: name, table: "ExerciseNames")`
- [x] 3.2 Create `Setory/ExerciseNames.xcstrings` with one key per bundled exercise id (40 keys from `exercises.json`), English values matching the stored names
- [x] 3.3 Switch all display sites to `localizedName`: exercise picker and series rows in `ContentView`, `SetEntrySheet` navigation title, `RoutineDetailView` series rows, and the exercise-name summary used by `RoutineListView` (keep `WorkoutSession.exerciseNames` canonical for unit tests; add a localized accessor for the view)
- [x] 3.4 Sort the exercise picker in memory by `localizedName` using `localizedStandardCompare` (SwiftData can't sort on computed properties)

## 4. Spanish translations

- [x] 4.1 Translate all UI keys in `Localizable.xcstrings` to Spanish, including plural variants (reps/min/series — "1 serie"/"N series") and the accessibility value
- [x] 4.2 Translate the 40 exercise names in `ExerciseNames.xcstrings` to Spanish (e.g. `bench-press` → "Press de banca")
- [x] 4.3 Audit both catalogs: no user-facing key missing an `es` value; build succeeds (a malformed catalog fails the build)

## 5. Tests

- [x] 5.1 Pin UI test launches to English by adding `-AppleLanguages (en)` and `-AppleLocale en_US` to `launchArguments` in `WorkoutLoggingUITests` and `RoutineHistoryUITests` (alongside the existing `-uitest-reset` flag)
- [x] 5.2 Add a unit test asserting every exercise id in `exercises.json` has a Spanish display-name entry in `ExerciseNames.xcstrings`
- [x] 5.3 Run the unit test suite; confirm `ModelTests`, `RoutineSummaryTests`, `CatalogSeederTests` still pass (stored names remain English)
- [x] 5.4 Run the UI test suite on a simulator and confirm all English-literal assertions pass under the pinned locale

## 6. Verification

- [x] 6.1 Run the app in a Spanish-locale simulator and walk every screen (tab bar, logging calendar, set-entry sheet, routines list, routine detail): all text in Spanish, dates/weekdays in Spanish, exercise and muscle names translated (scripted XCUITest walkthrough under `es_ES` + screenshot)
- [x] 6.2 Verify plural behavior: a 1-rep series shows "1 rep" (en) and Spanish counterparts; a 1-series routine shows "1 serie" on a Spanish device ("1 repetición · 40,5 kg" draft row; "1 serie"/"2 series" on Rutinas)
- [x] 6.3 Verify decimal-comma weight entry ("40,5") still stores 40.5 kg under the Spanish locale (typed "40,5" on the es decimal pad; row renders "40,5 kg" from the stored 40.5)
- [x] 6.4 Run the app in an unsupported language (e.g. French) and confirm English fallback (fr_FR launch shows "Workout Log", "No series yet", English tabs)
