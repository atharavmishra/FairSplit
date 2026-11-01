import 'package:fairsplit/core/money.dart';
import 'package:fairsplit/core/upi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAmount', () {
    expect(parseAmount('100'), 10000);
    expect(parseAmount('100.5'), 10050);
    expect(parseAmount('1,200.75'), 120075);
    expect(parseAmount(' 0.01 '), 1);
    expect(parseAmount('1.234'), isNull);
    expect(parseAmount('-5'), isNull);
    expect(parseAmount('abc'), isNull);
    expect(parseAmount(''), isNull);
  });

  test('formatting', () {
    expect(amountToPlain(10050), '100.50');
    expect(amountToPlain(5), '0.05');
    expect(formatAmount(12345678), '₹1,23,456.78');
  });

  test('upi link', () {
    final uri = upiPayUri(upiId: 'rahul@okicici', payeeName: 'Rahul', amount: 25050);
    expect(uri.scheme, 'upi');
    expect(uri.queryParameters['pa'], 'rahul@okicici');
    expect(uri.queryParameters['am'], '250.50');
    expect(isValidUpiId('rahul@okicici'), isTrue);
    expect(isValidUpiId('not-an-id'), isFalse);
  });
}
