# Add Progress Charts & Stats

## Why

The app already persists every set the user logs — dates, reps, weights, durations, and muscle targets — but none of it is visible as progress: there is no way to see whether bench press is going up, how much weekly volume each muscle group gets, or how consistently the user trains. A progress screen turns the data the user is already entering into the payoff that makes them keep logging, and it requires no new data entry at all.

## What Changes

- Add a new **Progress root tab** (fourth tab) with three sections:
  - **Training overview**: workouts per week over recent weeks as a bar chart, plus headline counts (sessions and total series in the current week/month).
  - **Muscle balance**: series volume per muscle group for a selected recent period, so under- and over-trained muscles are visible at a glance.
  - **Exercise progression entry point**: a searchable list of exercises the user has actually performed, leading to per-exercise progression charts.
- Add a **per-exercise progression screen** charting the exercise's history over time:
  - Strength: max weight per session and total volume (reps × weight) per session.
  - Cardio: duration per session.
  - Personal-record markers (best set so far) highlighted on the chart, with the all-time best summarized.
- Link the **exercise detail screen's history section** to the new per-exercise progression screen.
- All charts render with **Swift Charts** (system framework, no new dependency) and show localized empty states when there is not enough data.

## Capabilities

### New Capabilities

- `progress-stats`: the Progress tab — training overview chart, muscle-balance volume summary, performed-exercise list, and the per-exercise progression screen with PR markers.

### Modified Capabilities

- `exercise-detail`: the personal-history section gains navigation to the exercise's progression screen (only when history exists).
- `localization`: the enumerated "every screen renders localized" scenario extends to the Progress tab and progression screen; new UI strings (axis labels, period pickers, empty states) need English and Spanish entries.

## Impact

- **New views**: Progress tab view (overview + muscle balance + exercise list) and exercise progression view; `RootTabView` gains a fourth tab.
- **New service**: a stats aggregation provider (pure functions over fetched `WorkoutSession`/`WorkoutSeries`, in the style of `ExerciseHistoryProvider`) computing weekly session counts, per-muscle series volume, and per-exercise time series — unit-testable without UI.
- **Frameworks**: Swift Charts (bundled with iOS 16+; app targets iOS 17+). No persistence or model changes — read-only aggregation over existing SwiftData models.
- **Existing views**: `ExerciseDetailView` history section gains a navigation link.
- **Resources**: new keys in `Localizable.xcstrings` with Spanish translations.
- **Tests**: unit tests for the aggregation provider (week bucketing, volume math, PR detection, empty data); UI tests for the new tab, chart empty states, and detail-to-progression navigation.
