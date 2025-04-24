// lib/utils/formatters.dart
import 'package:intl/intl.dart'; // Import the intl package for formatting

// --- Currency Formatter ---
// Formats numbers into a currency string (e.g., €1,234.56)
// Using 'de_DE' locale for Euro symbol (€) and appropriate separators.
// You can adjust the locale and symbol as needed.
final currencyFormatter = NumberFormat.currency(
  locale: 'de_DE', // German locale (uses ',' for decimal, '.' for thousands)
  symbol: '€',      // Euro symbol
);

// --- Date Formatter Function ---
// Formats a DateTime object into a string (e.g., '24.04.2025')
// Using 'dd.MM.yyyy' pattern which is common in Germany/Austria.
String formatDate(DateTime date) {
  // Create a DateFormat instance with the desired pattern
  final DateFormat formatter = DateFormat('dd.MM.yyyy');
  // Format the date and return the string
  return formatter.format(date);
}

// You could add more formatters here later, e.g.:
// String formatTimestamp(DateTime timestamp) {
//   return DateFormat('dd.MM.yyyy HH:mm').format(timestamp);
// }
//
// String formatPercentage(double value) {
//   return NumberFormat.percentPattern('de_DE').format(value); // e.g., value = 0.75 -> "75 %"
// }