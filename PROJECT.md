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
| 2026-10-13 | Walking and running take a duration from the user; calories burned are estimated as intensity factor × body weight × hours, using the weight from Personal settings. Only weight lifting is a fixed per-session amount. | Calories burned depend heavily on time. |
| 2026-10-13 | Water is its own Diary section with quick-add amounts in ml, not a food search. | Water is not a meal and should take one tap to log. |
| 2026-10-13 | Food source tabs appear only for datasets that are present (USDA and Custom for now). NCCDB is not included. | NCCDB is commercially licensed and cannot be bundled; data-driven tabs let new sources appear automatically. |
| 2026-10-13 | Calorie calculator: resting calories by Mifflin-St Jeor; maintenance = resting × activity factor (sedentary 1.2, light 1.375, moderate 1.55, very active 1.725, extra active 1.9); target = maintenance + goal offset (extreme cut −750, medium cut −500, light cut −250, maintain 0, light gain +250, medium gain +500 kcal). | Standard, widely used formula and factors. |
| 2026-10-13 | A calculated target is never below 1,200 kcal; the user can override the target by hand with any value. | An extreme cut on a small, sedentary person would otherwise produce an unsafe figure. |
| 2026-10-13 | Exercise intensity factors: walking 3.5, running 9.8; a weight-lifting session counts as 60 minutes at 3.5. Calories = factor × body weight (kg) × hours. | Standard MET values; not yet implemented. |
| 2026-10-13 | Diary charts are rings. Intake is split by the calories from protein, carbs and fat (4 / 4 / 9 kcal per gram). Expenditure is resting + everyday activity + logged exercise. Remaining is a meter of intake against the budget. | Rings leave room for the headline number in the middle; a two-slice pie is a poor way to show progress, so Remaining is a meter. |
| 2026-10-13 | Budget = calorie target + exercise calories; remaining = budget − intake. | Exercise earns extra food for the day. Risk: the activity level may already include regular exercise, which would count it twice. Revisit when phase 2 workouts arrive. |
| 2026-10-13 | Diary sections, in order: Breakfast, Lunch, Dinner, Water, Snacks, Other, Exercise. Each has its own plus button; exercise is its own section rather than an option under every meal. | Exercise does not belong to a meal. |
| 2026-10-13 | An exercise entry stores its calories when logged. | Changing body weight later must not rewrite past days. |
| 2026-10-14 | Under the Diary rings are only three full-width bars: protein, carbs and fat, each filling toward its daily target. The breakdowns of expenditure (resting, activity, exercise) and of remaining (target, exercise, eaten) move to the Statistics page. | The Diary should show only the most important figures; detail belongs in Statistics. |
| 2026-10-13 | Macro targets are set in the Profile as Standard, Percent of calories, or Grams. Standard is 20% protein / 50% carbohydrate / 30% fat of the calorie target, converted at 4 / 4 / 9 kcal per gram. Percentages must total 100. | Standard sits inside the commonly advised ranges (protein 10–35%, carbohydrate 45–65%, fat 20–35%); gram targets stay fixed when the calorie target changes. |
| 2026-10-14 | Food search matches the start of words ("cook" finds "cooked", not "uncooked"), every typed word must match, and shorter names rank first. | Matching inside words returned opposites such as "uncooked" for "cooked". |
| 2026-10-16 | Each USDA food carries its USDA category (stored in `foods.category`, schema version 7), shown under its name as "USDA · Poultry Products". Search ranks processed and prepared categories last (luncheon meats, fast food, restaurant food, prepared meals, baby food), before applying shortest-name-first. Databases seeded earlier gain categories on next launch. | Searching "chicken breast" returned a processed deli roll (14.6 g protein) above plain roasted chicken breast (31 g), because USDA gives whole foods long names. |
| 2026-10-23 | USDA FNDDS 2021–2023 (5,431 foods and dishes "as eaten", 16,718 portion sizes, public domain) is bundled as a second dataset (`assets/data/usda_fndds.tsv` and `usda_fndds_servings.tsv`, about 1 MB together), shown as the "FNDDS" source tab with its WWEIA categories. Datasets are built by `tool/build_usda_seed.dart <sr\|fndds\|foundation> <csv-dir>`, and each is imported on first launch independently. Baby food, formula, cold cuts and sausages rank last in search. | Adds prepared dishes and realistic portions ("1 medium breast"), and plainer entries for common foods. |
| 2026-10-23 | USDA Foundation Foods (April 2026 release, public domain) is bundled as a third dataset, shown as the "Foundation" tab: 329 staple foods with 128 serving sizes. Only entries with an energy value are kept (90 partial lab analyses dropped), and where USDA has several records under one name the newest is kept. The build tool takes each nutrient from a list of preferred FDC fields, so energy falls back to the Atwater values and sugars and carbohydrate to their alternative fields when the classic field is empty. | The most recent and detailed analyses of everyday foods. |
| 2026-10-23 | The app tracks 60 nutrients: energy, water, alcohol, caffeine; carbohydrates, fiber, sugars, starch; fat and its saturated, mono- and polyunsaturated, trans, cholesterol, omega-3 (ALA, EPA, DHA) and omega-6 parts; protein and 18 amino acids; 13 vitamins; 10 minerals. They are defined once in `lib/core/domain/nutrient_catalog.dart` (name, unit, group, preferred USDA fields, FDA daily value), which both the app and the build tool read. The database nutrient list is synced from it on every launch, so adding a nutrient needs no migration. | The main gap against Cronometer. One list avoids the app and the data files drifting apart. |
| 2026-10-23 | Seed files have a header row naming each column by nutrient code, so columns can be added without breaking older parsers. Each bundled dataset has a version (now 2); when an update ships a higher version, foods already imported are brought up to date in place (schema version 8 adds the `dataset_imports` table). | Existing installs gain the new nutrients without losing diary entries or re-importing. |
| 2026-10-23 | The nutrition facts screen shows every nutrient the food has data for, in cards by group, with a bar wherever a daily value exists; nutrients without data are hidden. The custom food form keeps energy and macros at the top and the rest in collapsible groups. Comparison shows only nutrients at least one compared food has, under group headings. | 60 rows would otherwise be mostly blanks. |
| 2026-10-25 | Statistics has three tabs sharing one range picker: a single row showing the current range that opens a list (Today by default, Last 7 days, Last 30 days, Custom range). Overview: total surplus or deficit for the range, a line chart of calories eaten against calories burned, a chart of each day's surplus (red) or deficit (blue), and the energy breakdown moved off the Diary. Macros: averages against targets, the calorie split against the target split, and the top five foods for protein, carbs and fat. Nutrients: every tracked nutrient against general daily values, with sodium, saturated fat and cholesterol treated as limits that turn red past 100%. | The user wanted detailed numbers and charts per topic, the calorie trend over a range, and where each macro came from. |
| 2026-10-25 | Statistics averages and totals count only days with food logged; unlogged days show as gaps in the charts. Calories burned per day are the profile's maintenance calories plus that day's exercise, and surplus or deficit is eaten minus burned. | An unlogged day is missing data, not a day of eating nothing. Limitation: burned calories use the current profile for every past day, since profile history is not kept. |
| 2026-10-25 | A diary entry remembers the serving it was logged with (schema version 9 adds `serving_quantity` and `serving_label`) and shows it, such as "2 × 1 tbsp · 42.0 g". Grams stay the stored amount that all totals use. | Logged servings should read the way they were entered. |
| 2026-10-25 | Display options live on a Display screen opened from Personal settings: energy in kcal or kJ, food weight in grams or ounces, water in ml or fl oz, and whether foods open at 100 g or their first serving. They are stored as key and value rows (schema version 10 adds `app_settings`) and change only what is shown and typed; the database keeps kcal, grams and ml. Body measurements stay metric. | Conversion at the edges keeps every total, chart and stored value in one unit. |
| 2026-10-25 | Backup is one JSON file (format 1) saved and opened through `file_picker`, from a Backup screen opened from Personal settings. It holds settings, the profile, custom foods and meals (nutrients by code, servings, ingredients), and the diary, water and exercise entries. Bundled foods are referred to by dataset and dataset id, never copied. Restoring replaces all of that in one transaction; entries for bundled foods this install lacks are left out and counted. | Ids differ between installs, but dataset ids do not, so a backup works on a fresh install and stays small. |
| 2026-10-14 | In the Foods tab, tapping a food opens its nutrition facts (with an adjustable amount and an Add to diary button). From a Diary section's plus button, tapping a food goes straight to the amount dialog. | Browsing wants detail; logging wants speed. |
| 2026-10-14 | Foods have serving sizes ("1 cup", "1 large") alongside grams, chosen from a unit dropdown wherever an amount is entered. USDA's 14,449 servings are bundled as `assets/data/usda_sr_servings.tsv` and imported separately from the foods. Diary entries still store grams only. | Logging "1 egg" is more practical than weighing; a separate import lets databases seeded earlier gain servings. |
| 2026-10-14 | The nutrition facts screen shows a calorie headline, a stacked bar of calories by macro, and a bar per nutrient filled toward a daily amount: the user's own calorie and macro targets when a profile exists, otherwise a general 2,000 kcal diet. Fiber, saturated fat and sodium use general daily values (28 g, 20 g, 2,300 mg); sugars have none. | Bars make a food's contribution to the day readable at a glance. |
| 2026-10-14 | A meal is stored as a food (source `meal`) plus its ingredient list. Its nutrition facts per 100 g are calculated from the ingredients when it is saved, and it gets a "1 meal" serving weighing the whole recipe. | Being a food, a meal can be searched, logged, compared and reused as an ingredient with no special cases. Trade-off: editing an ingredient later does not update the meal until the meal is saved again. |
| 2026-10-14 | Deleting a custom food or meal only hides it from search (`deleted_at`); the row stays. Bundled foods cannot be deleted. | Diary history and meals that use the food must keep working. |
| 2026-10-14 | Custom foods can have their own serving sizes, and custom foods and meals can be edited from their nutrition facts screen. | Same convenience as bundled foods. |
| 2026-10-14 | Comparison holds two to four foods, matched either at the same weight or at the weights that supply the same amount of one chosen nutrient. Each nutrient is a card with one bar per food, scaled to the largest value; a food with none of the matched nutrient is shown as such. It opens from the Foods tab and from a food's nutrition facts. | Covers both "100 g of rice vs 100 g of pasta" and "10 g of carbs from each". Four is what fits a phone. |
| 2026-10-14 | Compared foods are identified by letters (A, B, C, D). With three or four foods the bars are a single colour. | The chart colours already mean protein, carbs, fat and the expenditure parts; reusing them for foods would break "a colour always means the same thing". |
| 2026-10-16 | With exactly two foods, each nutrient is one split bar: A (blue, `compareA`) fills from the left and B (dark blue, `compareB`) from the right, in proportion to their amounts, with the values at each end. The weight and amount inputs are centred instead of full width. | Easier to read at a glance than two separate bars. B was first amber; changed on 2026-10-16 to a darker shade of the same blue at the user's request. The two shades differ by about 1.9:1 in contrast, and each side is also labelled by position and value. |
| 2026-10-13 | Custom meals are recipes: several foods with amounts, nutrition computed from them. Custom foods keep manual entry of nutrition facts. | Avoids retyping facts for meals built from known foods. |

### Technical

| Date | Decision | Why |
|---|---|---|
| 2026-10-11 | Flutter, targeting Android and iOS. | One codebase; existing Flutter experience. |
| 2026-10-11 | SQLite through Drift for storage. | Typed queries, migrations, fast aggregation for statistics. |
| 2026-10-11 | Riverpod for state (chosen over Bloc). | Less boilerplate than Bloc for a solo project, and it doubles as dependency injection. |
| 2026-10-11 | fl_chart for charts. | Covers pie, bar, line and radar. |
| 2026-10-11 | Nutrient amounts are stored per 100 g; each food records its source. | One base unit makes scaling, comparison and display conversion simple. |
| 2026-10-11 | USDA SR Legacy (7,793 foods) is bundled as `assets/data/usda_sr.tsv`, built by `tool/build_usda_seed.dart`, and imported on first launch. | Public domain, small (0.7 MB), good generic coverage. |
| 2026-10-11 | Diary days are stored as local `yyyy-MM-dd` text. | Avoids time-zone shifts moving entries between days. |
| 2026-10-11 | Web platform enabled for development in Chrome. | Fast UI iteration without an emulator. Not a release target. |
| 2026-10-12 | VS Code always runs web on port 8080. | Browser storage is per address; a random port loses the data each run. |

### Architecture

Decided 2026-10-13: feature-first folders with three layers per feature, so
features stay independent and phase 2 can be added without touching phase 1.

```
lib/
  main.dart
  app/                 app widget and the navigation shell
  core/                shared by every feature
    database/          AppDatabase, tables, day keys
    domain/            enums and constants the schema and features share
    formatting/
  features/
    <feature>/
      data/            repositories: the only code that queries the database
      domain/          plain Dart models and rules, no Flutter imports
      presentation/    screens, widgets, Riverpod providers and notifiers
test/                  mirrors lib/
```

Rules:

- **Widgets draw and forward user actions.** They never use `AppDatabase` or
  write queries; they read providers and call repository or notifier methods.
- **Repositories are the only code that talks to the database.** One per
  feature, exposed through a Riverpod provider.
- **Business rules are plain Dart in `domain/`** (calorie formula, exercise
  estimates, comparison maths) and are unit-tested without Flutter.
- **State**: Riverpod. Data comes from `StreamProvider`/`FutureProvider` over
  repositories; shared screen state lives in a `Notifier`. Short-lived state
  owned by one widget (text being typed, the selected tab) may stay in that
  widget.
- **Dependencies point one way**: `presentation → domain ← data`, and
  features may depend on `core` but `core` never depends on a feature. A
  feature may use another feature's screens or repositories only where it
  genuinely builds on it (the diary uses foods, not the reverse).
- **Imports** are always `package:mizan/...`; the analyzer enforces this and
  a stricter rule set in `analysis_options.yaml`.
- **Every repository and domain rule has tests**; `test/` mirrors `lib/`.
- Drift row classes (`Food`, `Nutrient`) are used directly as models until a
  feature needs something they cannot express.

### Visual style

Decided 2026-10-13: a single dark theme in blue shades with white text.

Every colour is defined once in `lib/core/theme/app_colors.dart`, and the
theme in `lib/core/theme/app_theme.dart` is built from it. Widgets never
hard-code a colour. To restyle the app, change the value there and update
this table.

| Token | Hex | Used for |
|---|---|---|
| `background` | `#0A1222` | Page background, app bar |
| `surface` | `#101B30` | Navigation bar |
| `surfaceRaised` | `#16243D` | Cards, dialogs, bottom sheets |
| `outline` | `#263654` | Dividers, borders, empty chart track |
| `primary` | `#3B82F6` | Buttons, links, the Remaining ring |
| `primaryBright` | `#60A5FA` | Accents |
| `primaryMuted` | `#1D3A6B` | Selected navigation item, selected segments |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#B4C2DA` | Supporting text, labels |
| `textMuted` | `#7F8FAB` | Hints, field borders |
| `good` | `#0CA30C` | Positive state |
| `warning` | `#FAB219` | Warning state |
| `critical` | `#E66767` | Errors, over-budget |
| `chartProtein` | `#3987E5` | Protein |
| `chartCarbs` | `#D95926` | Carbohydrates |
| `chartFat` | `#199E70` | Fat |
| `chartResting` | `#C98500` | Resting calories |
| `chartActivity` | `#D55181` | Everyday activity calories |
| `chartExercise` | `#9085E9` | Exercise calories |
| `compareA` | `#3987E5` | Food A when exactly two foods are compared |
| `compareB` | `#2058B0` | Food B when exactly two foods are compared |

Chart rules:

- The two chart trios (macros; expenditure parts) were checked for
  colour-blind separation and for contrast against `surfaceRaised`. Re-check
  before changing any of them.
- Status colours are reserved for state and never used as a series colour.
- A colour always means the same thing: protein is blue on every screen.
- Numbers and labels stay in text colours; a coloured dot beside them carries
  identity.

### Environment

- Flutter SDK at `C:\src\flutter` (stable channel).
- Repository: https://github.com/alikashlan10/Mizan (private).
- Development on Windows covers Android and Chrome; iOS builds need a Mac.

## Current state

As of 2026-10-25, in the dark blue theme with schema version 10:

| Phase 1 page | State |
|---|---|
| Diary | Done: rings for intake, expenditure and remaining, macro target bars, five food sections, water and exercise logging. |
| Foods | Done: search with source tabs (All, USDA, Foundation, FNDDS, Custom, Meals), nutrition facts with daily-target bars, serving sizes. |
| Customization | Done: custom foods with servings, meals built from foods, edit and delete. |
| Comparison | Done: two to four foods by weight or by one nutrient. |
| Personal settings | Done: calorie calculator, macro targets and display options (kcal/kJ, g/oz, ml/fl oz, starting amount). Backup to and restore from a file. Body measurements are metric only. |
| Statistics | Done: Overview, Macros and Nutrients tabs over any date range. |

Sixty nutrients are tracked; see `lib/core/domain/nutrient_catalog.dart`.

## Open questions

- **Exercise and the budget.** Exercise calories are added to what can be
  eaten; this double counts if the activity level already includes them.
