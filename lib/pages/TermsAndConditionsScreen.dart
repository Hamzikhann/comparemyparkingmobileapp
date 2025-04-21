import 'package:flutter/material.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Terms & Conditions',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          color: Colors.black, fontSize: 16, height: 1.6),
                      children: [
                        TextSpan(
                          text: 'Effective Date: 04/21/2025\n\n',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        TextSpan(
                          text:
                              'Welcome to Parking app! These Terms and Conditions govern your use of our valet parking services.\n\n',
                        ),
                        TextSpan(
                          text: '1. Acceptance\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'By signing up or using the app, you agree to these terms and our Privacy Policy.\n\n',
                        ),
                        TextSpan(
                          text: '2. Use of Service\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '- To provide accurate registration information.\n'
                              '- To use the app for lawful valet parking purposes.\n'
                              '- Not to misuse the platform or interfere with other users.\n\n',
                        ),
                        TextSpan(
                          text: '3. Booking and Payments\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '- You can book and cancel parking spots using the app.\n'
                              '- Payments are securely processed via Stripe.\n'
                              '- We reserve the right to change pricing and refund policies at any time.\n\n',
                        ),
                        TextSpan(
                          text: '4. User Responsibilities\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '- You are responsible for securing your account.\n'
                              '- You are responsible for retrieving your vehicle at the end of your session.\n'
                              '- We are not liable for delays or third-party failures.\n\n',
                        ),
                        TextSpan(
                          text: '5. App Access\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We may update, suspend, or remove features or access at our discretion.\n\n',
                        ),
                        TextSpan(
                          text: '6. Intellectual Property\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'All content, trademarks, and services belong to Parking app or its licensors.\n\n',
                        ),
                        TextSpan(
                          text: '7. Limitation of Liability\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We are not responsible for any loss, damage, or injury resulting from your use of the app or services.\n\n',
                        ),
                        TextSpan(
                          text: '8. Termination\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We reserve the right to suspend or terminate your account if you violate these terms.\n\n',
                        ),
                        TextSpan(
                          text: '9. Contact Us\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'For questions or support, please contact: support@parkingapp.com\n',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
