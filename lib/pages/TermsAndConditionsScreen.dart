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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('TERMS & CONDITIONS'),
                    _subTitle('Version: 1.0'),
                    _subTitle('Last Updated: 28/11/2025'),
                    const SizedBox(height: 16),
                    _sectionTitle('Table of Contents'),
                    _bullet('1. About Us'),
                    _bullet('2. Our Role as an Intermediary'),
                    _bullet('3. Vendor Information & Security Declarations'),
                    _bullet('4. Bookings & Payment'),
                    _bullet('5. Cancellations, Amendments & Refunds'),
                    _bullet('6. Your Responsibilities'),
                    _bullet('7. Liability & Disclaimers'),
                    _bullet('8. Customer Complaints & Claims'),
                    _bullet('9. Website Use & Acceptable Behaviour'),
                    _bullet('10. Data Protection & Privacy'),
                    _bullet('11. Changes to These Terms'),
                    _bullet('12. Governing Law'),
                    _bullet('13. Company Information'),
                    _divider(),
                    _sectionTitle('1. ABOUT US'),
                    _paragraph(
                        'www.comparemyairportparking.com (“the Website”) is operated by Park Pilot Ltd (“we”, “us”, “our”).'),
                    _paragraph(
                        'We provide an online comparison and booking platform for airport parking services offered by independent third-party providers (“Vendors”).'),
                    _paragraph(
                        'We do not own, manage or operate any car parks. All parking services listed are provided solely by Vendors.'),
                    _divider(),
                    _sectionTitle('2. OUR ROLE AS AN INTERMEDIARY'),
                    _paragraph(
                        'When you book through our Website, you enter into a contract directly with the Vendor.'),
                    _paragraph(
                        'We act only as an intermediary facilitating the booking process.'),
                    _paragraph(
                        'We are not responsible for the provision, safety or quality of Vendor services.'),
                    _divider(),
                    _sectionTitle(
                        '3. VENDOR INFORMATION & SECURITY DECLARATIONS'),
                    _paragraph(
                        'All Vendor information is supplied directly by the Vendor and displayed as provided.'),
                    _paragraph(
                        'Security terms such as CCTV, gated or patrolled are Vendor declarations only.'),
                    _paragraph(
                        'We do not guarantee the accuracy or effectiveness of security measures.'),
                    _divider(),
                    _sectionTitle('4. BOOKINGS & PAYMENT'),
                    _paragraph(
                        'You must ensure booking details are accurate before confirmation.'),
                    _paragraph(
                        'A booking is confirmed once payment is completed and confirmation email is issued.'),
                    _paragraph(
                        'Payments are processed through secure third-party providers.'),
                    _divider(),
                    _sectionTitle('5. CANCELLATIONS, AMENDMENTS & REFUNDS'),
                    _paragraph(
                        'Cancellation and refund policies vary by Vendor.'),
                    _paragraph('Some bookings may be non-refundable.'),
                    _paragraph(
                        'Refunds may take up to 14 working days if applicable.'),
                    _divider(),
                    _sectionTitle('6. YOUR RESPONSIBILITIES'),
                    _paragraph(
                        'You must allow sufficient time for parking, transfers and airport check-in.'),
                    _paragraph(
                        'You are responsible for securing your vehicle and reviewing Vendor terms.'),
                    _divider(),
                    _sectionTitle('7. LIABILITY & DISCLAIMERS'),
                    _paragraph(
                        'We do not exclude liability that cannot be excluded under UK law.'),
                    _paragraph(
                        'We are not liable for vehicle damage, theft, missed flights or Vendor negligence.'),
                    _paragraph(
                        'Our total liability is limited to the booking fee paid to us.'),
                    _divider(),
                    _sectionTitle('8. CUSTOMER COMPLAINTS & CLAIMS'),
                    _paragraph(
                        'Complaints must be directed to the Vendor providing the service.'),
                    _paragraph(
                        'We may assist communication but are not responsible for dispute resolution.'),
                    _divider(),
                    _sectionTitle('9. WEBSITE USE & ACCEPTABLE BEHAVIOUR'),
                    _paragraph(
                        'You must not misuse the Website or submit illegal or offensive content.'),
                    _divider(),
                    _sectionTitle('10. DATA PROTECTION & PRIVACY'),
                    _paragraph(
                        'We process personal data according to our Privacy Policy.'),
                    _paragraph(
                        'Booking data is shared with Vendors only to fulfil reservations.'),
                    _divider(),
                    _sectionTitle('11. CHANGES TO THESE TERMS'),
                    _paragraph(
                        'We may update these terms at any time. Continued use signifies acceptance.'),
                    _divider(),
                    _sectionTitle('12. GOVERNING LAW'),
                    _paragraph(
                        'These terms are governed by the laws of England & Wales.'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 UI Helpers

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _subTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          '• $text',
          style: const TextStyle(fontSize: 14),
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(),
      );
}
