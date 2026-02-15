import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingInfoModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';

class ReserveBookingScreen extends StatefulWidget {
  const ReserveBookingScreen({Key? key}) : super(key: key);

  @override
  State<ReserveBookingScreen> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<ReserveBookingScreen> {
  int _currentStep =
      0; // 0: Your Details, 1: Flight Details, 2: Vehicle Details

  // Controllers
  // Step 1
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String selectedTitle = "Mr";
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Step 2
  final TextEditingController outBoundController = TextEditingController();
  final TextEditingController inBoundController = TextEditingController();
  final TextEditingController departureFlightController =
      TextEditingController();
  final TextEditingController returnFlightController = TextEditingController();

  // Step 3
  final TextEditingController vehicleLookupController = TextEditingController();
  final TextEditingController vehicleRegNoController = TextEditingController();
  final TextEditingController carMakerController =
      TextEditingController(); // Manufacturer
  final TextEditingController carYearController = TextEditingController();
  final TextEditingController carModelController =
      TextEditingController(); // Model (previously year was mixed?)
  final TextEditingController carColorController = TextEditingController();
  final TextEditingController numPassengersController = TextEditingController();
  String transmissionType = 'Auto';

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfileInfo();
  }

  void _loadUserProfileInfo() {
    if (Globals.user != null) {
      setState(() {
        firstNameController.text = Globals.user!.firstName;
        lastNameController.text = Globals.user!.lastName;
        emailController.text = Globals.user!.email;
        phoneController.text = Globals.user!.phoneNo;
        selectedTitle = "Mr"; // Default since UserModel doesn't have title
      });
    }
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _handleVehicleLookup() async {
    String regNo = vehicleLookupController.text.trim();
    if (regNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a registration number")));
      return;
    }

    try {
      final response = await GeneralRepository().lookupVehicle(regNo);
      if (response.success && response.data?.vehicleDescription != null) {
        print(response.data!.vehicleDescription!);
        final vd = response.data!.vehicleDescription!;
        setState(() {
          vehicleRegNoController.text = regNo;
          carMakerController.text = vd.manufacturer ?? "";
          carModelController.text = vd.model ?? "";
          carYearController.text = vd.year ?? "";
          carColorController.text = vd.colour ?? "";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No data found. Please enter details manually.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed. Please enter manually.")));
    }
  }

  // Validation Helpers
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  // --- Step Content Builders ---

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Title"),
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Color(0xFFEFF1F3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTitle,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: ["Mr", "Mrs", "Miss", "Ms", "Other"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: 'Archivo',
                            color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedTitle = newValue!;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("First Name"),
                    _buildTextField(
                        controller: firstNameController,
                        hint: "Enter First Name",
                        validator: (v) => validateRequired(v, "First Name")),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Last Name"),
                    _buildTextField(
                        controller: lastNameController,
                        hint: "Enter Last Name",
                        validator: (v) => validateRequired(v, "Last Name")),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildLabel("Phone Number"),
          _buildTextField(
              controller: phoneController,
              hint: "Enter Phone Number",
              keyboardType: TextInputType.phone,
              validator: (v) => validateRequired(v, "Phone Number")),
          SizedBox(height: 16.h),
          _buildLabel("Email"),
          _buildTextField(
              controller: emailController,
              hint: "Enter Email",
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail),
          if (Globals.user == null) ...[
            SizedBox(height: 16.h),
            _buildLabel("Password"),
            _buildTextField(
              controller: passwordController,
              hint: "Enter Password",
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildLabel("Confirm Password"),
            _buildTextField(
              controller: confirmPasswordController,
              hint: "Confirm Password",
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),
          ],
          SizedBox(height: 40.h), // Spacing for button
          Align(
            alignment: Alignment.centerRight,
            child: _buildButton("Continue", _handleStep1Continue),
          )
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Outbound Terminal"),
          _buildTextField(
              controller: outBoundController,
              hint: "Enter Outbound Terminal",
              validator: (v) => validateRequired(v, "Outbound Terminal")),
          SizedBox(height: 16.h),
          _buildLabel("Inbound Terminal"),
          _buildTextField(
              controller: inBoundController,
              hint: "Enter Inbound Terminal",
              validator: (v) => validateRequired(v, "Inbound Terminal")),
          SizedBox(height: 16.h),
          _buildLabel("Departure Flight"),
          _buildTextField(
              controller: departureFlightController,
              hint: "Enter Departure Flight",
              validator: (v) => validateRequired(v, "Departure Flight")),
          SizedBox(height: 16.h),
          _buildLabel("Return Flight"),
          _buildTextField(
              controller: returnFlightController,
              hint: "Enter Return Flight",
              validator: (v) => validateRequired(v, "Return Flight")),
          SizedBox(height: 60.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton("Back", _onBackPressed, isSecondary: true),
              _buildButton("Continue", () {
                if (_formKey2.currentState!.validate()) {
                  setState(() => _currentStep = 2);
                }
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Lookup Header
          Text("Vehicle Lookup",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo')),
          Text(
            "Enter your vehicle registration number to auto-fill vehicle details",
            style: TextStyle(
                fontSize: 12.sp, color: Colors.grey, fontFamily: 'Archivo'),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                controller: vehicleLookupController,
                hint: "Enter register number",
              )),
              SizedBox(width: 8.w),
              InkWell(
                onTap: _handleVehicleLookup,
                child: Container(
                  height: 50.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                      color: Color(0xFF2E5B5B), // primary dark green
                      borderRadius: BorderRadius.circular(8.r)),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              )
            ],
          ),
          SizedBox(height: 24.h),
          _buildLabel("Vehicle Registration No"),
          _buildTextField(
              controller: vehicleRegNoController,
              hint: "Enter Registration No",
              validator: (v) => validateRequired(v, "Registration No")),
          SizedBox(height: 16.h),
          _buildLabel("Car Manufacturer"),
          _buildTextField(
              controller: carMakerController,
              hint: "Enter Manufacturer",
              validator: (v) => validateRequired(v, "Manufacturer")),
          SizedBox(height: 16.h),
          _buildLabel("Car Year"),
          _buildTextField(
              controller: carYearController,
              hint: "Enter Year",
              keyboardType: TextInputType.number,
              validator: (v) => validateRequired(v, "Year")),
          SizedBox(height: 16.h),
          _buildLabel("Car Model"),
          _buildTextField(
              controller: carModelController,
              hint: "Enter Model",
              validator: (v) => validateRequired(v, "Model")),
          SizedBox(height: 16.h),
          _buildLabel("Car Color"),
          _buildTextField(
              controller: carColorController,
              hint: "Enter Color",
              validator: (v) => validateRequired(v, "Color")),
          SizedBox(height: 16.h),
          _buildLabel("Transmission"),
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Color(0xFFEFF1F3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: transmissionType,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: ["Auto", "Manual"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: 'Archivo',
                            color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    transmissionType = newValue!;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildLabel("No of Passengers"),
          _buildTextField(
              controller: numPassengersController,
              hint: "Enter No of Passengers",
              keyboardType: TextInputType.number,
              validator: (v) => validateRequired(v, "No of Passengers")),
          SizedBox(height: 20.h),
          Row(
            children: [
              Checkbox(
                value: agreedToTerms,
                onChanged: (val) =>
                    setState(() => agreedToTerms = val ?? false),
                activeColor: Color(0xFF2E5B5B),
              ),
              Expanded(
                  child: Text("I agree to terms & conditions",
                      style:
                          TextStyle(fontFamily: 'Archivo', fontSize: 13.sp))),
            ],
          ),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton("Back", _onBackPressed, isSecondary: true),
              _buildButton("Complete Reservation", _submitForm),
            ],
          )
        ],
      ),
    );
  }

  void _handleStep1Continue() async {
    if (!_formKey1.currentState!.validate()) return;

    if (Globals.user == null) {
      try {
        String firstName = firstNameController.text.trim();
        String lastName = lastNameController.text.trim();

        // Show loading
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Creating account...')));

        final value = await GeneralRepository().signup(
          title: selectedTitle,
          firstName: firstName,
          lastName: lastName,
          email: emailController.text.trim(),
          phoneNo: phoneController.text.trim(),
          password: passwordController.text.trim(),
          confirmPassword: confirmPasswordController.text.trim(),
        );

        // Set global user like in SignupScreen
        Globals.user = value;
        Globals.roleTitle = value.roleTitle;
        await SharedStorage.saveUser(value);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully')));

        setState(() => _currentStep = 1);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup failed: ${e.toString()}')));
      }
    } else {
      setState(() => _currentStep = 1);
    }
  }

  void _submitForm() async {
    if (!_formKey3.currentState!.validate()) {
      return;
    }

    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please accept terms & conditions')));
      return;
    }

    // Take names directly from controllers
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();

    // Create Booking Info
    final bookingInfo = BookingInfoModel(
      outBoundTerminal: outBoundController.text,
      inBoundTerminal: inBoundController.text,
      departureFlight: departureFlightController.text,
      returnFlight: returnFlightController.text,
      title: selectedTitle,
      firstName: firstName,
      lastName: lastName,
      phone: phoneController.text,
      email: emailController.text,
      vehicleRegNo: vehicleRegNoController.text,
      carMaker: carMakerController.text,
      carModel: carModelController.text,
      carYear: carYearController.text,
      carColor: carColorController.text,
      noOfPassengers: numPassengersController.text.isEmpty
          ? "1"
          : numPassengersController.text,
      type: transmissionType,
    );

    Globals.booking_info_model = bookingInfo;
    Navigator.pushNamed(context, MyRoutes.payment);
  }

  // --- UI Helpers ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Archivo',
            color: Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      Widget? suffixIcon,
      FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(fontFamily: 'Archivo', fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
        filled: true,
        fillColor: Color(0xFFEFF1F3),
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Color(0xFF2E5B5B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: TextStyle(fontSize: 11.sp, height: 0.8),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed,
      {bool isSecondary = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary
            ? Color(0xFFEFF1F3)
            : Color(0xFF4A6F56), // Green vs Grey
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w600,
          color: isSecondary ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(0, "Your Details"),
          Expanded(
              child: Divider(
                  color:
                      _currentStep >= 1 ? Color(0xFF4A6F56) : Colors.grey[300],
                  thickness: 2)),
          _buildStepCircle(1, "Flight Details"),
          Expanded(
              child: Divider(
                  color:
                      _currentStep >= 2 ? Color(0xFF4A6F56) : Colors.grey[300],
                  thickness: 2)),
          _buildStepCircle(2, "Vehicle Details"),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex, String label) {
    bool isActive = _currentStep >= stepIndex;
    bool isCurrent = _currentStep == stepIndex;
    return Column(
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF4A6F56) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
                color: isActive ? Color(0xFF4A6F56) : Colors.grey[400]!,
                width: 2),
          ),
          child: Center(
            child: Text(
              "${stepIndex + 1}",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: isActive ? Color(0xFF4A6F56) : Colors.grey[500],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _onBackPressed();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _onBackPressed,
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Color(0xFFEFF1F3),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: 20.sp,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      "Complete Your Booking",
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Archivo',
                          color: Color(0xFF1A1A2E)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        "Secure your parking reservation in just a few steps",
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                            fontFamily: 'Archivo'),
                      ),
                      _buildStepper(),
                      SizedBox(height: 10.h),
                      if (_currentStep == 0) _buildStep1(),
                      if (_currentStep == 1) _buildStep2(),
                      if (_currentStep == 2) _buildStep3(),
                      SizedBox(height: 40.h),
                    ],
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
