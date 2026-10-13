/// Formats a nutrient or weight amount: one decimal below 100, none above.
String formatAmount(double value) =>
    value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
