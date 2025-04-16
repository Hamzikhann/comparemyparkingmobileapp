import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  Future<void> makePayment(int amount, String currency) async {
    try {
      // 1. Call your backend to get the client secret
      final response = await http.post(
        Uri.parse('https://your-backend.com/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount, // in cents (i.e. $15.00)
          'currency': 'currency',
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your App Name',
        ),
      );

      // 3. Show the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. On success: get reference id
      //final paymentIntentId = clientSecret.split('_secret')[0];

      // ✅ Call booking API
    } catch (e) {
      print('Stripe error: $e');
    }
  }
}
