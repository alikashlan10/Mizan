/// Formats a nutrient or weight amount: one decimal below 100, none above.
String formatAmount(double value) =>
    value >= 100 ? value.round().toString() : value.toStringAsFixed(1);

/// A whole number with thousands separators, such as 1,234 or −250.
String formatWhole(double value) {
  final rounded = value.round();
  final grouped = rounded.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return rounded < 0 ? '−$grouped' : grouped;
}
