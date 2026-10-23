// Builds the bundled food files from a USDA FoodData Central CSV download
// (https://fdc.nal.usda.gov/download-datasets):
//
//   sr     "SR Legacy"            -> assets/data/usda_sr.tsv, usda_sr_servings.tsv
//   fndds  "Survey Foods (FNDDS)" -> assets/data/usda_fndds.tsv,
//                                    usda_fndds_servings.tsv
//
// Usage: dart run tool/build_usda_seed.dart <sr|fndds> <extracted-csv-dir>
import 'dart:io';

/// The nutrients written to the output, in column order, as FDC nutrient
/// numbers. Must match the nutrient codes listed in
/// lib/features/foods/data/food_seed.dart.
const nutrientNumbers = [208, 203, 205, 204, 291, 269, 606, 307];

/// How one FDC dataset differs from the others.
class Dataset {
  const Dataset({
    required this.output,
    required this.nutrientsByNumber,
    required this.categoryFile,
    required this.portionLabel,
  });

  /// Base name of the output files in assets/data.
  final String output;

  /// Whether food_nutrient.csv refers to nutrients by their number (208)
  /// rather than by their id (1008).
  final bool nutrientsByNumber;

  /// The CSV that names the categories in food.csv's category column.
  final String categoryFile;

  /// The serving label for a row of food_portion.csv, or null to skip it.
  final String? Function(List<String> row) portionLabel;
}

final datasets = {
  'sr': Dataset(
    output: 'usda_sr',
    nutrientsByNumber: false,
    categoryFile: 'food_category.csv',
    // "1" + "cup, chopped".
    portionLabel: (f) {
      final unit = f[6].trim();
      if (unit.isEmpty) return null;
      final amount = double.tryParse(f[3]) ?? 1;
      final count = amount == amount.roundToDouble()
          ? amount.toInt().toString()
          : amount.toString();
      return '$count $unit';
    },
  ),
  'fndds': Dataset(
    output: 'usda_fndds',
    nutrientsByNumber: true,
    categoryFile: 'wweia_food_category.csv',
    // "1 medium breast"; "Quantity not specified" is not a real serving.
    portionLabel: (f) {
      final label = f[5].trim();
      return label.isEmpty || label == 'Quantity not specified' ? null : label;
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

List<List<String>> readCsv(String path) => [
  for (final line in File(path).readAsLinesSync().skip(1)) parseCsvLine(line),
];

String clean(String text) => text.replaceAll('\t', ' ').trim();

void main(List<String> args) {
  final dataset = args.length == 2 ? datasets[args[0]] : null;
  if (dataset == null) {
    stderr.writeln(
      'Usage: dart run tool/build_usda_seed.dart <sr|fndds> <csv-dir>',
    );
    exit(64);
  }
  final dir = args[1];

  // food_nutrient.csv uses ids or numbers depending on the dataset; map
  // whichever it uses onto an output column.
  final numberById = {
    for (final f in readCsv('$dir/nutrient.csv'))
      int.parse(f[0]): int.tryParse(f[3].split('.').first),
  };
  final columnByNumber = {
    for (final (i, number) in nutrientNumbers.indexed) number: i,
  };
  int? columnOf(int key) =>
      columnByNumber[dataset.nutrientsByNumber ? key : numberById[key]];

  final amounts = <String, List<String>>{};
  for (final f in readCsv('$dir/food_nutrient.csv')) {
    final col = columnOf(int.parse(f[2]));
    if (col == null) continue;
    amounts.putIfAbsent(
      f[1],
      () => List.filled(nutrientNumbers.length, ''),
    )[col] = f[3];
  }

  final categories = <String, String>{
    for (final f in readCsv('$dir/${dataset.categoryFile}'))
      // food_category.csv is id, code, name; the WWEIA file is id, name.
      f[0]: clean(f.length > 2 ? f[2] : f[1]),
  };

  // Columns: source id, name, the nutrients above, category.
  final rows = <String>[];
  for (final f in readCsv('$dir/food.csv')) {
    final values = amounts[f[0]];
    if (values == null) continue;
    rows.add([f[0], clean(f[2]), ...values, categories[f[3]] ?? ''].join('\t'));
  }
  final out = File('assets/data/${dataset.output}.tsv')
    ..createSync(recursive: true);
  out.writeAsStringSync('${rows.join('\n')}\n');
  stdout.writeln('Wrote ${rows.length} foods to ${out.path}');

  // Serving sizes: food id, order, label such as "1 cup, chopped", grams.
  final servings = <String>[];
  for (final f in readCsv('$dir/food_portion.csv')) {
    final grams = double.tryParse(f[7]);
    if (!amounts.containsKey(f[1]) || grams == null || grams <= 0) continue;
    final label = dataset.portionLabel(f);
    if (label == null) continue;
    servings.add([f[1], f[2], clean(label), f[7]].join('\t'));
  }
  final servingsOut = File('assets/data/${dataset.output}_servings.tsv');
  servingsOut.writeAsStringSync('${servings.join('\n')}\n');
  stdout.writeln('Wrote ${servings.length} servings to ${servingsOut.path}');
}
