import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/widgets/reserveBooking/CustomTextFeild.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedCardType = 'Visa';
  bool saveCard = false;

  final List<Map<String, String>> cardTypes = [
    {'type': 'MasterCard', 'image': 'assets/images/master.png'},
    {'type': 'Visa', 'image': 'assets/images/visa.png'},
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardHolderNameController = TextEditingController(); // Added
  final TextEditingController cardNumbercontroller = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Payment',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card type selector
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cardTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final card = cardTypes[index];
                            final isSelected = selectedCardType == card['type'];
                            return GestureDetector(
                              onTap: () => setState(() => selectedCardType = card['type']!),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  card['image']!,
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cardholder Name Field - Added this section
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Cardholder Name",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        hintText: "Name",
                        controller: cardHolderNameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Cardholder name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Card Number Field
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Card Number",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        hintText: "1234 5678 9101 1121",
                        controller: cardNumbercontroller,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Card number is required";
                          if (value.replaceAll(' ', '').length != 16) return "Enter 16-digit card number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Expiry Date and CVV Fields
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text("Expiration Date",
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Archivo')),
                                ),
                                SizedBox(height: 8.h),
                                CustomTextField(
                                  hintText: "MM/YY",
                                  controller: expiryDateController,
                                  keyboardType: TextInputType.datetime,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return "Required";
                                    final regex = RegExp(r'^\d{2}/\d{2}$');
                                    if (!regex.hasMatch(value)) return "MM/YY format only";
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text("CVV",
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Archivo')),
                                ),
                                SizedBox(height: 8.h),
                                CustomTextField(
                                  hintText: "123",
                                  controller: cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return "Required";
                                    if (value.length != 3) return "3-digit CVV";
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Save Card Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: saveCard,
                            onChanged: (value) => setState(() => saveCard = value!),
                          ),
                          const Text("Save card details"),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pay Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Handle payment logic
                              debugPrint("Payment Success ✅");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Pay USD 59.28',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Your personal data will be used to process your order, support your experience and for other purposes described in our privacy policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                    ],
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