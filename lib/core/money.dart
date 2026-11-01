import 'package:intl/intl.dart';

/// All money in the app is an `int` count of the smallest currency unit
/// (paise for INR). Never use doubles for stored amounts.

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// Formats paise as a rupee string, e.g. 10050 -> "₹100.50".
String formatAmount(int paise) => _inr.format(paise / 100);

/// Parses user input like "100", "100.5" or "1,200.75" into paise.
/// Returns null for empty, negative, malformed, or more than 2 decimals.
int? parseAmount(String input) {
  final s = input.trim().replaceAll(',', '');
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(s);
  if (match == null) return null;
  final rupees = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return rupees * 100 + int.parse(fraction);
}

/// Paise as a plain decimal string without symbol, e.g. 10050 -> "100.50".
String amountToPlain(int paise) {
  final rupees = paise ~/ 100;
  final rest = (paise % 100).toString().padLeft(2, '0');
  return '$rupees.$rest';
}
