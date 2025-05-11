import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingInfoModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/PrimaryButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/widgets/reserveBooking/CustomTextFeild.dart';

class ReserveBookingScreen extends StatefulWidget {
  const ReserveBookingScreen({Key? key}) : super(key: key);

  @override
  State<ReserveBookingScreen> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<ReserveBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Flight Details
  final TextEditingController departureFlightController =
      TextEditingController();
  final TextEditingController returnFlightController = TextEditingController();
  final TextEditingController inBoundController = TextEditingController();
  final TextEditingController outBoundController = TextEditingController();

  // User Details
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String selectedTitle = "Mr";
  // Vehicle Details
  final TextEditingController vehicleRegNoController = TextEditingController();
  final TextEditingController carMakerController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController numPassengersController = TextEditingController();
  final TextEditingController carColorController = TextEditingController();

  bool agreedToTerms = false;

  void _onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    } else if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

@override
void initState() {
  super.initState();
  _loadSavedBookingInfo();
}

Future<void> _loadSavedBookingInfo() async {
  final savedInfo = await SharedStorage.loadBookingInfo();
  if (savedInfo != null && mounted) {
    setState(() {
      // Only fill if the field is empty
      if (outBoundController.text.isEmpty) outBoundController.text = savedInfo.outBoundTerminal;
      if (inBoundController.text.isEmpty) inBoundController.text = savedInfo.inBoundTerminal;
      if (departureFlightController.text.isEmpty) departureFlightController.text = savedInfo.departureFlight;
      if (returnFlightController.text.isEmpty) returnFlightController.text = savedInfo.returnFlight;
      
      // For title, we might want to always use the saved one if available
      selectedTitle = savedInfo.title;
      
      // Only fill name if it's still the default value
      if (firstNameController.text == Globals.user?.firstName || firstNameController.text.isEmpty) {
        firstNameController.text = savedInfo.firstName;
      }
      if (lastNameController.text == Globals.user?.lastName || lastNameController.text.isEmpty) {
        lastNameController.text = savedInfo.lastName;
      }
      
      if (phoneController.text.isEmpty) phoneController.text = savedInfo.phone;
      
      // Only fill email if it's still the default value
      if (emailController.text == Globals.user?.email || emailController.text.isEmpty) {
        emailController.text = savedInfo.email;
      }
      
      // Vehicle details
      if (vehicleRegNoController.text.isEmpty) vehicleRegNoController.text = savedInfo.vehicleRegNo;
      if (carMakerController.text.isEmpty) carMakerController.text = savedInfo.carMaker;
      if (carModelController.text.isEmpty) carModelController.text = savedInfo.carModel;
      if (carColorController.text.isEmpty) carColorController.text = savedInfo.carColor;
      if (numPassengersController.text.isEmpty) numPassengersController.text = savedInfo.noOfPassengers;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed(context);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                greeting: "Registration",
                showBackButton: true,
                onBackPressed: () => _onBackPressed(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Flight Details",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: "OutBound Terminal",
                                controller: outBoundController,
                                validator: (val) =>
                                    validateRequired(val, "OutBound Terminal"),
                              ),
                            
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "InBound Terminal",
                                controller: inBoundController,
                                validator: (val) =>
                                    validateRequired(val, "InBound Terminal"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text("Departure Flight",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo')),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text("Return Flight",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo')),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: departureFlightController,
                                validator: (val) =>
                                    validateRequired(val, "Departure Flight"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: returnFlightController,
                                validator: (val) =>
                                    validateRequired(val, "Return Flight"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("User Details",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 16.h),
                        CustomDropdown(
                          hint: "Title",
                          height: 45.h,
                          items: const ["Mr", "Mrs", "Others"],
                          isSearchable: false,
                          selectedItem: selectedTitle, // Add this line to set the initial selected item
                          onSelectItem: (item) {
                            setState(() {
                              selectedTitle = item!;
                            });
                          },
                        ),
                        SizedBox(height: 16.h),
                        Text("Name",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: "First",
                                controller: firstNameController,
                                defaultValue: Globals.user!.firstName,
                                validator: (val) =>
                                    validateRequired(val, "First name"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "Last",
                                controller: lastNameController,
                                defaultValue: Globals.user!.lastName,
                                validator: (val) =>
                                    validateRequired(val, "Last name"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("Phone",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (val) => validateRequired(val, "Phone"),
                        ),
                        SizedBox(height: 16.h),
                        Text("Email",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "**********",
                          controller: emailController,
                          defaultValue: Globals.user!.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        SizedBox(height: 24.h),
                        Text("Vehicle Detail",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 24.h),
                        Text("Vehicle Registration No",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "",
                          controller: vehicleRegNoController,
                          validator: (val) =>
                              validateRequired(val, "Vehicle Registration No"),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text("Car Maker",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo')),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text("Car Model",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Archivo')),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: carMakerController,
                                validator: (val) =>
                                    validateRequired(val, "Car Maker"),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                hintText: "",
                                controller: carModelController,
                                validator: (val) =>
                                    validateRequired(val, "Car Model"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text("Car Color",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "",
                          controller: carColorController,
                          validator: (val) =>
                              validateRequired(val, "car color"),
                        ),
                        SizedBox(height: 16.h),
                        Text("No of  Passengers",
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Archivo')),
                        SizedBox(height: 8.h),
                        CustomTextField(
                          hintText: "",
                          controller: numPassengersController,
                          validator: (val) =>
                              validateRequired(val, "numberOfPassengers"),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Checkbox(
                              value: agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreedToTerms = value ?? false;
                                });
                              },
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return const Color(0xFF201A56);
                                  }
                                  return Colors.grey.shade300;
                                },
                              ),
                              checkColor: Colors.white,
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "I agree to ",
                                  children: [
                                    TextSpan(
                                      text: "terms & conditions",
                                      style: TextStyle(
                                          color: colors.primary,
                                          decoration: TextDecoration.underline),
                                    ),
                                    const TextSpan(text: "."),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        PrimaryButton(
                          text: "Proceed",
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (agreedToTerms) {
                                // Create the booking info model
                                final bookingInfo = BookingInfoModel(
                                  outBoundTerminal: outBoundController.text,
                                  inBoundTerminal: inBoundController.text,
                                  departureFlight: departureFlightController.text,
                                  returnFlight: returnFlightController.text,
                                  title: selectedTitle,
                                  firstName: firstNameController.text,
                                  lastName: lastNameController.text,
                                  phone: phoneController.text,
                                  email: emailController.text,
                                  vehicleRegNo: vehicleRegNoController.text,
                                  carMaker: carMakerController.text,
                                  carModel: carModelController.text,
                                  carColor: carColorController.text,
                                  noOfPassengers: numPassengersController.text,
                                );

                                // Show dialog to ask if user wants to save info
                                bool? saveInfo = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Save Information"),
                                    content: Text(
                                        "Do you want to save this information for future use?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text("Yes"),
                                      ),
                                    ],
                                  ),
                                );

                                if (saveInfo == true) {
                                  await SharedStorage.saveBookingInfo(bookingInfo);
                                }
                                else{
                                  await SharedStorage.removeBookingInfo();
                                }

                                // Proceed to next screen
                                Globals.booking_info_model = bookingInfo;
                                Navigator.pushNamed(
                                  context,
                                  MyRoutes.payment,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please accept terms & conditions')),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
