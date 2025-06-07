import 'package:intl/intl.dart';


final currencyFormatter = NumberFormat.currency(
  locale: 'de_DE',
  symbol: '€',
);

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('dd.MM.yyyy');
  return formatter.format(date);
}
