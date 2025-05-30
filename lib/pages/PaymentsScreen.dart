import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/CardsModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedCardType = 'Visa';
  bool saveCard = false;
  List<CardsModel> savedCards = [];

  final List<Map<String, String>> cardTypes = [
    {'type': 'MasterCard', 'image': 'assets/images/master.png'},
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardHolderNameController =
      TextEditingController();
  final TextEditingController cardNumbercontroller = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    final cards = await SharedStorage.loadSavedCards();
    setState(() {
      savedCards = cards;
    });
  }

    

  Future<void> _handlePayment(String referenceNo) async {
    if (_formKey.currentState!.validate()) {
      // Save card information if required
      if (saveCard) {
        final card = CardsModel(
          cardHolderName: cardHolderNameController.text,
          cardNumber: cardNumbercontroller.text,
          expiryDate: expiryDateController.text,
          cvv: cvvController.text,
          cardType: selectedCardType,
        );
        await SharedStorage.saveCard(card);
        await _loadSavedCards();
      }

      // Prepare the booking data
      final bookingData = {
        "startDate": Globals.startDate,
        "startTime": Globals.startTime,
        "endDate": Globals.endDate,
        "endTime": Globals.endTime,
        "airport": "STN",
        "outboundTerminal": Globals.booking_info_model?.outBoundTerminal,
        "outboundFlightNo": "00000",
        "inboundTerminal": Globals.booking_info_model?.inBoundTerminal,
        "inboundFlightNo": "00000",
        "title": Globals.booking_info_model?.title,
        "firstName": Globals.booking_info_model?.firstName,
        "lastName": Globals.booking_info_model?.lastName,
        "email": Globals.booking_info_model?.email,
        "phoneNo": Globals.booking_info_model?.phone,
        "vehicleRegistrationNo": Globals.booking_info_model?.vehicleRegNo,
        "vehicleManufacturer": Globals.booking_info_model?.carMaker,
        "vehicleModel": Globals.booking_info_model?.carModel,
        "vehicleColor": Globals.booking_info_model?.carColor,
        "numberOfPassengers": Globals.booking_info_model?.noOfPassengers,
        "type": Globals.booking_info_model?.type,
        "userId": Globals.user?.id,
        "name": Globals.option?.name ?? '',
        "price": Globals.option?.price ?? '',
        "description": Globals.option?.description ?? '',
        "bulletPoints": Globals.option?.bulletPoints ?? [],
        "totalPrice": Globals.option?.price ?? '',
        "referenceNo": referenceNo,
      };

      try {
        final resultMessage = await GeneralRepository().bookParking(
          startDate: bookingData['startDate'] as String,
          startTime: bookingData['startTime'] as String,
          endDate: bookingData['endDate'] as String,
          endTime: bookingData['endTime'] as String,
          airport: bookingData['airport'] as String,
          outboundTerminal: bookingData['outboundTerminal'] as String,
          outboundFlightNo: bookingData['outboundFlightNo'] as String,
          inboundTerminal: bookingData['inboundTerminal'] as String,
          inboundFlightNo: bookingData['inboundFlightNo'] as String,
          title: bookingData['title'] as String,
          firstName: bookingData['firstName'] as String,
          lastName: bookingData['lastName'] as String,
          email: bookingData['email'] as String,
          phoneNo: bookingData['phoneNo'] as String,
          vehicleRegistrationNo: bookingData['vehicleRegistrationNo'] as String,
          vehicleManufacturer: bookingData['vehicleManufacturer'] as String,
          vehicleModel: bookingData['vehicleModel'] as String,
          vehicleColor: bookingData['vehicleColor'] as String,
          numberOfPassengers: bookingData['numberOfPassengers'] as String,
          type: bookingData['type'] as String,
          userId: bookingData['userId'] as String,
          name: bookingData['name'] as String,
          price: bookingData['price'] as String,
          description: bookingData['description'] as String,
          bulletPoints: (bookingData['bulletPoints'] is List)
              ? List<String>.from(bookingData['bulletPoints'] as List)
              : [],
          totalPrice: bookingData['totalPrice'] as String,
          referenceNo: bookingData['referenceNo'] as String,
        );

        // You can check if the resultMessage matches your expected success value
        if (resultMessage.toString().contains("Booking")) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/success.svg', // <-- Make sure this file is in your assets
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Booking Successful!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your parking has been booked successfully.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushNamedAndRemoveUntil(
                          context, MyRoutes.mainPage, (_) => false);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking failed: $resultMessage")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

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
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildLabel("Card Payment"),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cardTypes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final card = cardTypes[index];
                            final isSelected = selectedCardType == card['type'];
                            return GestureDetector(
                              onTap: () => setState(
                                  () => selectedCardType = card['type']!),
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
                                  height: 300,
                                  width: 300,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: startStripePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  6), // 🔽 Reduce radius here
                            ),
                          ),
                          child: Text('Proceed to Pay £${Globals.option?.price}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Your personal data will be used to process your order, support your experience and for other purposes described in our privacy policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom),
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

  Padding _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Archivo',
        ),
      ),
    );
  }
  Future<void> startStripePayment() async {
  try {
    final response = await GeneralRepository().createPaymentIntent(
      amount: Globals.option?.price ?? "0",
      currency: "gbp",
    );

    final clientSecret = response['paymentIntent']?['client_secret'] ??
                        response['clientSecret'];

    if (clientSecret == null) {
      throw Exception('Missing client secret in response');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Your Parking App',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    final paymentId = response['paymentIntent']?['id'] ?? response['paymentId'];

    if (paymentId == null) {
      throw Exception('Missing payment ID in response');
    }

    await _handlePayment(paymentId);
    
  } on StripeException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment error: ${e.error.localizedMessage}")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${e.toString()}")),
    );
  }
}


}
