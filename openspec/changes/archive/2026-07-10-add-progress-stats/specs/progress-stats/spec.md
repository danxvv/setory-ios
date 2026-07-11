# progress-stats Specification (delta)

## ADDED Requirements

### Requirement: Progress tab
The app SHALL provide a "Progress" root tab, alongside the existing Log, Exercises, and Routines tabs, containing a training overview section, a muscle-balance section, and a list of performed exercises that navigates to per-exercise progression screens. When no workout sessions have been saved, the tab MUST show a localized empty state explaining that progress appears after logging workouts, instead of empty charts.

#### Scenario: Progress tab is reachable
- **WHEN** the user opens the app
- **THEN** the tab bar shows a fourth "Progress" tab, and selecting it shows the overview, muscle-balance, and exercise-progression sections

#### Scenario: Empty state before any workout
- **WHEN** the Progress tab is opened and no workout session has ever been saved
- **THEN** a localized empty state is shown and no chart is rendered

### Requirement: Training overview
The Progress tab SHALL display a bar chart of workouts per week for the most recent 8 calendar weeks (including the current week), bucketed using the device calendar's week boundaries, with weeks containing no sessions shown as zero. The section MUST also display headline counts: sessions and total series in the current calendar week and current calendar month.

#### Scenario: Weekly counts are charted
- **WHEN** the user has saved sessions in some of the last 8 weeks
- **THEN** the chart shows one bar per week with the correct session count, and weeks without sessions appear as zero

#### Scenario: Headline counts reflect current week and month
- **WHEN** the user has saved 2 sessions totaling 9 series this week and 5 sessions totaling 21 series this month
- **THEN** the overview shows 2 sessions / 9 series for the week and 5 sessions / 21 series for the month

### Requirement: Muscle balance summary
The Progress tab SHALL display, for a user-selected period of the current week or the current month, the number of logged series per muscle, counting each series once toward each primary muscle of its exercise (see `exercise-catalog` muscle-target metadata; secondary muscles are not counted). Muscles with zero series in the period MUST be omitted, muscles MUST be sorted by series count descending and labeled with localized muscle names, and a localized empty state MUST be shown when the period contains no series.

#### Scenario: Series are counted per primary muscle
- **WHEN** the selected period contains 6 series of exercises whose primary muscle is chest and 2 series of exercises whose primary muscles are back and biceps
- **THEN** the summary shows chest with 6, back with 2, and biceps with 2, in descending order

#### Scenario: Switching the period updates the summary
- **WHEN** the user switches the period picker from week to month
- **THEN** the muscle counts recompute over the current calendar month

#### Scenario: Empty period
- **WHEN** the selected period contains no logged series
- **THEN** a localized empty state is shown instead of the muscle list

### Requirement: Performed-exercise progression list
The Progress tab SHALL list every exercise that has at least one logged series, sorted alphabetically by localized display name, each row showing the localized name and category icon. The list MUST be searchable with case- and diacritic-insensitive matching on the localized name, MUST NOT include exercises that have never been performed, and selecting a row MUST push that exercise's progression screen.

#### Scenario: Only performed exercises are listed
- **WHEN** the catalog contains 50 exercises and the user has logged series for 7 of them
- **THEN** the progression list shows exactly those 7 exercises, sorted by localized name

#### Scenario: Search filters the list
- **WHEN** the user types "press" into the search field
- **THEN** only performed exercises whose localized name matches (ignoring case and diacritics) remain listed

#### Scenario: Row opens the progression screen
- **WHEN** the user taps a listed exercise
- **THEN** the progression screen for that exercise is pushed

### Requirement: Exercise progression screen
The app SHALL provide a progression screen for a single performed exercise charting one data point per saved session, in date order, with the metric determined by the exercise's category: strength exercises with at least one weighted set SHALL chart the maximum weight (kg) per session and the session's total volume (sum of reps × weight over weighted sets, omitting sessions with no weighted sets from both series); strength exercises with no weighted history SHALL chart the maximum repetitions per session; cardio exercises SHALL chart the longest duration per session. The chart MUST render for any history of one or more sessions, and axis values MUST use locale-aware number and date formatting.

#### Scenario: Weighted strength progression
- **WHEN** the user opens the progression screen for a strength exercise logged with weights across several sessions
- **THEN** the chart shows max weight per session and session volume, ordered by date

#### Scenario: Bodyweight strength progression
- **WHEN** the user opens the progression screen for a strength exercise whose logged sets never include a weight
- **THEN** the chart shows max repetitions per session

#### Scenario: Cardio progression
- **WHEN** the user opens the progression screen for a cardio exercise
- **THEN** the chart shows the longest duration per session

#### Scenario: Single-session history still renders
- **WHEN** the exercise has been performed in exactly one saved session
- **THEN** the chart renders that single data point without layout breakage

### Requirement: Personal-record markers
The progression screen SHALL mark each session where the exercise's running best set improved, using the same best-set ordering as the exercise detail screen (weight then reps for strength, reps when unweighted, duration for cardio), and SHALL summarize the all-time best set above the chart.

#### Scenario: PR sessions are marked
- **WHEN** the user's max bench-press weight improved in sessions 1, 3, and 6 of their history
- **THEN** those sessions carry a visible PR marker on the chart and the others do not

#### Scenario: All-time best is summarized
- **WHEN** the progression screen for an exercise is displayed
- **THEN** the all-time best set (matching the detail screen's best-set definition) is shown with localized value formatting
