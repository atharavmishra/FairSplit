import 'money.dart';

/// Builds a `upi://pay` link that opens GPay/PhonePe/Paytm etc. with the
/// payee and amount pre-filled. Supported by all UPI apps in India.
Uri upiPayUri({
  required String upiId,
  required String payeeName,
  required int amount,
  String note = 'FairSplit settle up',
}) {
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': upiId,
      'pn': payeeName,
      'am': amountToPlain(amount),
      'cu': 'INR',
      'tn': note,
    },
  );
}

bool isValidUpiId(String s) => RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$').hasMatch(s.trim());
