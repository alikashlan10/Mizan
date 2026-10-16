// Builds assets/data/usda_sr.tsv from the USDA FoodData Central "SR Legacy"
// CSV download (https://fdc.nal.usda.gov/download-datasets).
//
// Usage: dart run tool/build_usda_seed.dart <extracted-csv-dir>
import 'dart:io';

/// FDC nutrient ids in the column order of the output file. Must match the
/// nutrient codes listed in lib/features/foods/data/food_seed.dart.
const nutrientIds = [1008, 1003, 1005, 1004, 1079, 2000, 1258, 1093];

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

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/build_usda_seed.dart <csv-dir>');
    exit(64);
  }
  final dir = args.single;
  final column = {for (final (i, id) in nutrientIds.indexed) id: i};

  final amounts = <String, List<String>>{};
  for (final line in File('$dir/food_nutrient.csv').readAsLinesSync().skip(1)) {
    final f = parseCsvLine(line);
    final col = column[int.parse(f[2])];
    if (col == null) continue;
    amounts.putIfAbsent(f[1], () => List.filled(nutrientIds.length, ''))[col] =
        f[3];
  }

  final categories = <String, String>{
    for (final line in File('$dir/food_category.csv').readAsLinesSync().skip(1))
      if (parseCsvLine(line) case [final id, _, final description, ...])
        id: description,
  };

  // Columns: source id, name, the nutrients above, USDA food category.
  final rows = <String>[];
  for (final line in File('$dir/food.csv').readAsLinesSync().skip(1)) {
    final f = parseCsvLine(line);
    final values = amounts[f[0]];
    if (values == null) continue;
    final name = f[2].replaceAll('\t', ' ').trim();
    rows.add([f[0], name, ...values, categories[f[3]] ?? ''].join('\t'));
  }

  final out = File('assets/data/usda_sr.tsv')..createSync(recursive: true);
  out.writeAsStringSync('${rows.join('\n')}\n');
  stdout.writeln('Wrote ${rows.length} foods to ${out.path}');

  // Serving sizes: food id, order, label such as "1 cup, chopped", grams.
  final servings = <String>[];
  for (final line in File('$dir/food_portion.csv').readAsLinesSync().skip(1)) {
    final f = parseCsvLine(line);
    final grams = double.tryParse(f[7]);
    final unit = f[6].replaceAll('\t', ' ').trim();
    if (!amounts.containsKey(f[1]) || grams == null || grams <= 0) continue;
    if (unit.isEmpty) continue;
    final amount = double.tryParse(f[3]) ?? 1;
    final count = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    servings.add([f[1], f[2], '$count $unit', f[7]].join('\t'));
  }
  final servingsOut = File('assets/data/usda_sr_servings.tsv');
  servingsOut.writeAsStringSync('${servings.join('\n')}\n');
  stdout.writeln('Wrote ${servings.length} servings to ${servingsOut.path}');
}
