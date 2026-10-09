import 'package:intl/intl.dart' show NumberFormat, DateFormat;

String money(num value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} đ';
String shortDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
