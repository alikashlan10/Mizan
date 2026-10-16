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
| 2026-10-14 | In the Foods tab, tapping a food opens its nutrition facts (with an adjustable amount and an Add to diary button). From a Diary section's plus button, tapping a food goes straight to the amount dialog. | Browsing wants detail; logging wants speed. |
| 2026-10-14 | Foods have serving sizes ("1 cup", "1 large") alongside grams, chosen from a unit dropdown wherever an amount is entered. USDA's 14,449 servings are bundled as `assets/data/usda_sr_servings.tsv` and imported separately from the foods. Diary entries still store grams only. | Logging "1 egg" is more practical than weighing; a separate import lets databases seeded earlier gain servings. |
| 2026-10-14 | The nutrition facts screen shows a calorie headline, a stacked bar of calories by macro, and a bar per nutrient filled toward a daily amount: the user's own calorie and macro targets when a profile exists, otherwise a general 2,000 kcal diet. Fiber, saturated fat and sodium use general daily values (28 g, 20 g, 2,300 mg); sugars have none. | Bars make a food's contribution to the day readable at a glance. |
| 2026-10-14 | A meal is stored as a food (source `meal`) plus its ingredient list. Its nutrition facts per 100 g are calculated from the ingredients when it is saved, and it gets a "1 meal" serving weighing the whole recipe. | Being a food, a meal can be searched, logged, compared and reused as an ingredient with no special cases. Trade-off: editing an ingredient later does not update the meal until the meal is saved again. |
| 2026-10-14 | Deleting a custom food or meal only hides it from search (`deleted_at`); the row stays. Bundled foods cannot be deleted. | Diary history and meals that use the food must keep working. |
| 2026-10-14 | Custom foods can have their own serving sizes, and custom foods and meals can be edited from their nutrition facts screen. | Same convenience as bundled foods. |
| 2026-10-14 | Comparison holds two to four foods, matched either at the same weight or at the weights that supply the same amount of one chosen nutrient. Each nutrient is a card with one bar per food, scaled to the largest value; a food with none of the matched nutrient is shown as such. It opens from the Foods tab and from a food's nutrition facts. | Covers both "100 g of rice vs 100 g of pasta" and "10 g of carbs from each". Four is what fits a phone. |
| 2026-10-14 | Compared foods are identified by letters (A, B, C, D). With three or four foods the bars are a single colour. | The chart colours already mean protein, carbs, fat and the expenditure parts; reusing them for foods would break "a colour always means the same thing". |
| 2026-10-16 | With exactly two foods, each nutrient is one split bar: A (blue, `compareA`) fills from the left and B (amber, `compareB`) from the right, in proportion to their amounts, with the values at each end. The weight and amount inputs are centred instead of full width. | Easier to read at a glance than two separate bars. The two colours were checked as a pair; amber is close to `chartResting`, which never appears on this screen. |
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
| `compareB` | `#C4861A` | Food B when exactly two foods are compared |

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

As of 2026-10-14, in the dark blue theme with schema version 6:

| Phase 1 page | State |
|---|---|
| Diary | Done: rings for intake, expenditure and remaining, macro target bars, five food sections, water and exercise logging. |
| Foods | Done: search with source tabs (All, USDA, Custom, Meals), nutrition facts with daily-target bars, serving sizes. |
| Customization | Done: custom foods with servings, meals built from foods, edit and delete. |
| Comparison | Done: two to four foods by weight or by one nutrient. |
| Personal settings | Done: calorie calculator and macro targets. Metric units only. |
| Statistics | Not started; the tab is a placeholder. |

Eight nutrients are tracked: energy, protein, carbohydrates, fat, fiber,
sugars, saturated fat and sodium.

## Open questions

- **Statistics page.** Date-range statistics in grams and percentages, plus
  the expenditure and remaining breakdowns moved off the Diary.
- **Servings in the diary.** Entries store grams only, so "1 tbsp" is shown
  as "21 g".
- **Exercise and the budget.** Exercise calories are added to what can be
  eaten; this double counts if the activity level already includes them.
- **Full nutrient list.** The prototype tracks 8 nutrients; the target is
  the full vitamin, mineral, amino acid and fatty acid set.
- **Display options** for calories and amounts (kcal/kJ, g/oz, per 100 g or
  per serving): details still to be discussed.
