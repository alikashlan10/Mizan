# Mizan

Living record of what Mizan is for and every design and technical decision
taken so far. Update it whenever a decision is made or changed.

## Purpose

Mizan (ميزان, "scale / balance") is a personal mobile app for tracking
nutrition accurately, in the spirit of Cronometer, with features and
customization Cronometer restricts or lacks. It will later grow to cover
workout tracking and planning.

## Goals

- Accurate nutrition data from trusted, curated sources rather than
  crowd-sourced entries.
- Fully local: no backend, no account. All data lives on the device.
- Statistics for any day or date range, with no paywall or time limit.
- Head-to-head food comparison.
- User control over how calories and amounts are displayed.
- Android and iOS from one codebase.
- Built for personal use first; publishing is possible later.

## Phases

### Phase 1: Nutrition

| Page | What it does |
|---|---|
| **Diary** | Three pie charts for the selected day: intake, expenditure, and remaining to target (if a target is set). Sections for breakfast, lunch, dinner, snacks, water and other, each with a plus button to add food or exercise. |
| **Foods** | Search bar plus tabs: "All" (every source) and one tab per source (USDA, custom, others as they are added). Selecting a tab limits the search to that source. |
| **Comparison** | Two or more foods side by side, matched either by weight (100 g rice vs 100 g pasta) or by one nutrient (10 g of carbs from each, showing the grams needed and the remaining nutrients). |
| **Customization** | Create a custom food or a custom meal and enter its nutrition facts. |
| **Statistics** | (1) Overall statistics for a user-selected date range, in grams and percentages. (2) Breakdowns of each of the three Diary pie charts. |
| **Personal settings** | Calorie calculator: weight, height, gender, age and an optional goal produce a daily calorie target for the chosen level (medium cut, extreme cut, medium gain, and so on). |

Some of these will need extra pages or forms.

### Phase 2: Workouts

Workout tracking and planning. Not designed yet; phase 1 must leave room for
it in navigation and in the data model.

### Later

- Barcode scanning and branded foods (Open Food Facts).
- Backup: export and import to a file.
- Biometrics (weight history and similar).

## Decisions

### Product

| Date | Decision | Why |
|---|---|---|
| 2026-10-11 | App name is Mizan. | Means scale/balance; works in Arabic and English. |
| 2026-10-11 | Fully local, no backend. | Personal use first; no hosting or accounts to maintain. |
| 2026-10-11 | Barcode scanning and branded foods are deferred. | Branded datasets are several GB and cannot be bundled. |
| 2026-10-11 | Food data comes from trusted sources worldwide, plus manual user entries. | Accuracy is the point of the app. |
| 2026-10-13 | Scope expands to workouts as phase 2; phase 1 is nutrition. | Keep phase 2 in mind so it does not force a redesign. |
| 2026-10-13 | Navigation is a bottom bar: Diary, Foods, Workouts (phase 2, hidden until then), Statistics, Profile. No start page. Comparison and Customization live inside Foods. | Most opens are "log something today"; a chooser page costs a tap each time, and food and exercise share one daily view. |
| 2026-10-13 | Phase 1 exercise is a fixed choice of three types: cardio walking, cardio running, weight-lifting session. Each has an estimated effect on expenditure based on the user's personal information; a weight-lifting session uses a fixed average. | Keeps phase 1 simple while still filling the expenditure chart. |
| 2026-10-13 | Phase 2 workouts feed the same expenditure figure as phase 1 exercise. | One daily energy picture, whatever the source. |
| 2026-10-13 | Custom meals are recipes: several foods with amounts, nutrition computed from them. Custom foods keep manual entry of nutrition facts. | Avoids retyping facts for meals built from known foods. |

### Technical

| Date | Decision | Why |
|---|---|---|
| 2026-10-11 | Flutter, targeting Android and iOS. | One codebase; existing Flutter experience. |
| 2026-10-11 | SQLite through Drift for storage. | Typed queries, migrations, fast aggregation for statistics. |
| 2026-10-11 | Riverpod for state. | Simple and testable. |
| 2026-10-11 | fl_chart for charts. | Covers pie, bar, line and radar. |
| 2026-10-11 | Nutrient amounts are stored per 100 g; each food records its source. | One base unit makes scaling, comparison and display conversion simple. |
| 2026-10-11 | USDA SR Legacy (7,793 foods) is bundled as `assets/data/usda_sr.tsv`, built by `tool/build_usda_seed.dart`, and imported on first launch. | Public domain, small (0.7 MB), good generic coverage. |
| 2026-10-11 | Diary days are stored as local `yyyy-MM-dd` text. | Avoids time-zone shifts moving entries between days. |
| 2026-10-11 | Web platform enabled for development in Chrome. | Fast UI iteration without an emulator. Not a release target. |
| 2026-10-12 | VS Code always runs web on port 8080. | Browser storage is per address; a random port loses the data each run. |

### Environment

- Flutter SDK at `C:\src\flutter` (stable channel).
- Repository: https://github.com/alikashlan10/Mizan (private).
- Development on Windows covers Android and Chrome; iOS builds need a Mac.

## Current state

Working prototype: diary for any day with a kcal and macro summary, four meal
sections, food search over USDA and custom foods, and custom food creation
with 8 nutrients (energy, protein, carbs, fat, fiber, sugars, saturated fat,
sodium).

## Open questions

- **Exercise inputs.** Do walking and running take a duration (or distance)
  from the user, with only weight lifting being a fixed per-session amount?
  Which formula and constants to use for the estimates.
- **Water.** Proposed: its own Diary section with quick-add amounts in ml
  rather than a food search.
- **NCCDB.** It is commercially licensed and cannot be bundled without a
  licence. Source tabs should be driven by whichever datasets are present.
- **Full nutrient list.** The prototype tracks 8 nutrients; the target is
  the full vitamin, mineral, amino acid and fatty acid set.
- **Display options** for calories and amounts (kcal/kJ, g/oz, per 100 g or
  per serving): details still to be discussed.
