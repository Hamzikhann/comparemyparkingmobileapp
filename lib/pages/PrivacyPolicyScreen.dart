import 'package:flutter/material.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Privacy Policy',
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
                              'Your privacy is important to us. This Privacy Policy explains how Parking app ("we", "our", or "us") collects, uses, and protects your personal information.\n\n',
                        ),
                        TextSpan(
                          text: '1. Information We Collect\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '- Personal Information: Name, email address, phone number, and login credentials during account registration.\n'
                              '- Location Data: To help you find and book nearby valet parking spots.\n'
                              '- Camera & Photos Access: To allow you to upload and view images of your parked vehicle.\n'
                              '- Payment Information: Stripe handles payments. We do not store card details directly.\n'
                              '- Usage Data: Analytics about how you use the app, including booking and support interactions.\n\n',
                        ),
                        TextSpan(
                          text: '2. How We Use Your Information\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '- To provide parking services and manage your bookings.\n'
                              '- To show you your parking location and photo records.\n'
                              '- To enable secure Stripe payment processing.\n'
                              '- To provide 24/7 customer support.\n'
                              '- To improve app functionality and user experience.\n\n',
                        ),
                        TextSpan(
                          text: '3. Data Sharing\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We do not sell your data. We may share necessary information with:\n'
                              '- Stripe for payments.\n'
                              '- Customer support platforms.\n'
                              '- Government authorities if legally required.\n\n',
                        ),
                        TextSpan(
                          text: '4. Data Security\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We implement strong technical and administrative measures to protect your data.\n\n',
                        ),
                        TextSpan(
                          text: '5. Your Rights\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'You can update or delete your personal data anytime via the app settings or by contacting support.\n\n',
                        ),
                        TextSpan(
                          text: '6. Children’s Privacy\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'The app is not intended for users under 13 years of age.\n\n',
                        ),
                        TextSpan(
                          text: '7. Contact Us\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'If you have any questions about this Privacy Policy, email us at: support@parkingapp.com\n',
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
