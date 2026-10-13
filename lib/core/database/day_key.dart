import 'package:intl/intl.dart';

/// How a local calendar day is stored: `yyyy-MM-dd`, which sorts correctly
/// and is unaffected by time zones.
String dayKey(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
