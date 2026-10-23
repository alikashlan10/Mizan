// Builds the bundled food files from a USDA FoodData Central CSV download
// (https://fdc.nal.usda.gov/download-datasets):
//
//   sr     "SR Legacy"            -> assets/data/usda_sr.tsv, usda_sr_servings.tsv
//   fndds  "Survey Foods (FNDDS)" -> assets/data/usda_fndds.tsv,
//                                    usda_fndds_servings.tsv
//   foundation "Foundation Foods" -> assets/data/usda_foundation.tsv,
//                                    usda_foundation_servings.tsv
//
// Usage: dart run tool/build_usda_seed.dart <sr|fndds|foundation> <csv-dir>
import 'dart:io';

import 'package:mizan/core/domain/nutrient_catalog.dart';

/// The nutrients written to the output, one column each in catalogue order.
/// Each lists FDC nutrient ids in order of preference: newer datasets often
/// leave the classic field empty and report an alternative, such as energy
/// by Atwater factors instead of "Energy".
final nutrientColumns = [for (final n in nutrientCatalog) n.fdcIds];

/// Position of energy among [nutrientColumns].
final energyColumn = nutrientCatalog.indexWhere((n) => n.code == 'energy');

/// How one FDC dataset differs from the others.
class Dataset {
  const Dataset({
    required this.output,
    required this.nutrientsByNumber,
    required this.categoryFile,
    required this.portionLabel,
    this.dataType,
    this.requireEnergy = false,
    this.latestPerName = false,
  });

  /// Base name of the output files in assets/data.
  final String output;

  /// Whether food_nutrient.csv refers to nutrients by their number (208)
  /// rather than by their id (1008).
  final bool nutrientsByNumber;

  /// The CSV that names the categories in food.csv's category column.
  final String categoryFile;

  /// The serving label for a row of food_portion.csv, given measure unit
  /// names by id, or null to skip the row.
  final String? Function(List<String> row, Map<String, String> units)
  portionLabel;

  /// Only foods of this `data_type` are kept; the download also holds the
  /// lab samples behind them.
  final String? dataType;

  /// Whether to drop foods without an energy value. Some datasets publish
  /// partial analyses that are of no use for counting calories.
  final bool requireEnergy;

  /// Whether to keep only the most recent record (highest FDC id) when
  /// several foods share a name, as with re-analysed Foundation Foods.
  final bool latestPerName;
}

/// A whole-number amount without its decimals: "1.0" becomes "1".
String count(String amount) {
  final value = double.tryParse(amount) ?? 1;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

final datasets = {
  'sr': Dataset(
    output: 'usda_sr',
    nutrientsByNumber: false,
    categoryFile: 'food_category.csv',
    // "1" + "cup, chopped".
    portionLabel: (f, _) {
      final unit = f[6].trim();
      return unit.isEmpty ? null : '${count(f[3])} $unit';
    },
  ),
  'fndds': Dataset(
    output: 'usda_fndds',
    nutrientsByNumber: true,
    categoryFile: 'wweia_food_category.csv',
    // "1 medium breast"; "Quantity not specified" is not a real serving.
    portionLabel: (f, _) {
      final label = f[5].trim();
      return label.isEmpty || label == 'Quantity not specified' ? null : label;
    },
  ),
  'foundation': Dataset(
    output: 'usda_foundation',
    nutrientsByNumber: false,
    categoryFile: 'food_category.csv',
    dataType: 'foundation_food',
    requireEnergy: true,
    latestPerName: true,
    // "1" + "wedge" + "small (1/8 of small melon)". Units ending in " w" are
    // lab weighing steps, not servings.
    portionLabel: (f, units) {
      final unit = units[f[4]]?.trim() ?? '';
      if (unit.isEmpty || unit.endsWith(' w') || unit == 'undetermined') {
        return null;
      }
      final detail = [
        f[5],
        f[6],
      ].map((s) => s.trim()).where((s) => s.isNotEmpty);
      return ['${count(f[3])} $unit', ...detail].join(', ');
    },
  ),
};

List<String> parseCsvLine(String line) {
  final fields = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c != '"') {
        field.write(c);
      } else if (i + 1 < line.length && line[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      fields.add(field.toString());
      field.clear();
    } else {
      field.write(c);
    }
  }
  fields.add(field.toString());
  return fields;
}

/// Rows of a CSV file after its header. A quoted field may span several
/// lines, as some Foundation Foods descriptions do.
List<List<String>> readCsv(String path) {
  final rows = <List<String>>[];
  final pending = StringBuffer();
  for (final line in File(path).readAsLinesSync().skip(1)) {
    if (pending.isNotEmpty) pending.write(' ');
    pending.write(line);
    // An odd number of quotes means a quoted field is still open.
    final quotes = '"'.allMatches(pending.toString()).length;
    if (quotes.isOdd) continue;
    rows.add(parseCsvLine(pending.toString()));
    pending.clear();
  }
  return rows;
}

String clean(String text) => text.replaceAll('\t', ' ').trim();

void main(List<String> args) {
  final dataset = args.length == 2 ? datasets[args[0]] : null;
  if (dataset == null) {
    stderr.writeln(
      'Usage: dart run tool/build_usda_seed.dart '
      '<sr|fndds|foundation> <csv-dir>',
    );
    exit(64);
  }
  final dir = args[1];

  // food_nutrient.csv refers to nutrients by id, or in FNDDS by number;
  // translate numbers to ids so both read the same way.
  final idByNumber = {
    for (final f in readCsv('$dir/nutrient.csv')) f[3]: int.parse(f[0]),
  };
  final wanted = {for (final ids in nutrientColumns) ...ids};

  final keep = dataset.dataType == null
      ? null
      : {
          for (final f in readCsv('$dir/food.csv'))
            if (f[1] == dataset.dataType) f[0],
        };

  // Every wanted nutrient amount per food, keyed by nutrient id.
  final found = <String, Map<int, String>>{};
  for (final f in readCsv('$dir/food_nutrient.csv')) {
    if (keep != null && !keep.contains(f[1])) continue;
    final id = dataset.nutrientsByNumber ? idByNumber[f[2]] : int.parse(f[2]);
    if (id == null || !wanted.contains(id) || f[3].isEmpty) continue;
    (found[f[1]] ??= {})[id] = f[3];
  }
  // One value per column: the first preferred id the food has.
  final amounts = {
    for (final e in found.entries)
      e.key: [
        for (final ids in nutrientColumns)
          ids
              .map((id) => e.value[id])
              .firstWhere((v) => v != null, orElse: () => '')!,
      ],
  };

  final categories = <String, String>{
    for (final f in readCsv('$dir/${dataset.categoryFile}'))
      // food_category.csv is id, code, name; the WWEIA file is id, name.
      f[0]: clean(f.length > 2 ? f[2] : f[1]),
  };

  // Rows by FDC id, in file order.
  final rowsById = <String, String>{};
  final idByName = <String, String>{};
  for (final f in readCsv('$dir/food.csv')) {
    final values = amounts[f[0]];
    if (values == null) continue;
    if (dataset.requireEnergy && values[energyColumn].isEmpty) {
      amounts.remove(f[0]);
      continue;
    }
    final name = clean(f[2]);
    if (dataset.latestPerName) {
      final previous = idByName[name];
      if (previous != null) {
        if (int.parse(previous) > int.parse(f[0])) {
          amounts.remove(f[0]);
          continue;
        }
        rowsById.remove(previous);
        amounts.remove(previous);
      }
      idByName[name] = f[0];
    }
    rowsById[f[0]] = [
      f[0],
      name,
      categories[f[3]] ?? '',
      ...values,
    ].join('\t');
  }
  // A header names the columns, so the app reads them by nutrient code.
  final header = [
    'fdc_id',
    'name',
    'category',
    for (final n in nutrientCatalog) n.code,
  ];
  final rows = [header.join('\t'), ...rowsById.values];
  final out = File('assets/data/${dataset.output}.tsv')
    ..createSync(recursive: true);
  out.writeAsStringSync('${rows.join('\n')}\n');
  stdout.writeln('Wrote ${rows.length - 1} foods to ${out.path}');

  // Serving sizes: food id, order, label such as "1 cup, chopped", grams.
  final servings = <String>[];
  final units = {for (final f in readCsv('$dir/measure_unit.csv')) f[0]: f[1]};
  for (final f in readCsv('$dir/food_portion.csv')) {
    final grams = double.tryParse(f[7]);
    if (!amounts.containsKey(f[1]) || grams == null || grams <= 0) continue;
    final label = dataset.portionLabel(f, units);
    if (label == null) continue;
    servings.add([f[1], f[2], clean(label), f[7]].join('\t'));
  }
  final servingsOut = File('assets/data/${dataset.output}_servings.tsv');
  servingsOut.writeAsStringSync('${servings.join('\n')}\n');
  stdout.writeln('Wrote ${servings.length} servings to ${servingsOut.path}');
}
