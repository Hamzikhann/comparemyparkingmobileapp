import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/CustomTextField.dart';
import 'package:parkingapp/widgets/PrimaryButton.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';

class AddEditDriverScreen extends StatefulWidget {
  final Driver? driver;

  const AddEditDriverScreen({Key? key, this.driver}) : super(key: key);

  @override
  _AddEditDriverScreenState createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTitle;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      selectedTitle = widget.driver!.title;
      _firstNameController.text = widget.driver!.firstName;
      _lastNameController.text = widget.driver!.lastName;
      _emailController.text = widget.driver!.email;
      _phoneController.text = widget.driver!.phoneNo ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser(String title,
     String firstName,
     String lastName,
     String email,
     String phoneNo,
     String password,
     String confirmPassword) async {
    GeneralRepository().signup(
      title: title,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNo: phoneNo,
      password: password,
      confirmPassword: confirmPassword,
    ).then((value) {
      Alertify.showAlert(
        duration: 1,
        alertKey: 'signup',
        message: 'Driver Add successfully!',
        type: AlertType.success,
        onClose: () async {
          Globals.user = value;
          SharedStorage.saveUser(value);
          _emailController.clear();
          _passwordController.clear();
          await fetchDrivers();
          
        },
      );
    });
  }
  Future<void> fetchDrivers() async {
      try {
      final response = await GeneralRepository().getEmployeesWithBookings();
      final employeesData = response['data'] as List;
        Globals.drivers = employeesData.map((json) => Driver.fromJson(json)).toList();
     Navigator.pop(context);
    } catch (e) {
      
        print('Failed to load drivers: ${e.toString()}');
     
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
              title: widget.driver == null ? "Add Driver" : "Edit Driver",
              onBackPressed: () => Navigator.pop(context),
              onLogoutPressed: () {
                Globals.user = null;
                SharedStorage.removeFromSharedPreferences();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  MyRoutes.loginRoute, 
                  (route) => false
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      // Title Dropdown
                      CustomDropdown(
                        hint: "Title",
                        items: const ["Mr", "Mrs", "Do not want to Specify"],
                        isSearchable: false,
                        onSelectItem: (item) {
                          setState(() {
                            selectedTitle = item;
                          });
                        },
                      ),
                      SizedBox(height: 10.h),
                      // First Name
                      CustomTextField(
                        hintText: "First Name",
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.h),
                      // Last Name
                      CustomTextField(
                        hintText: "Last Name",
                        controller: _lastNameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.h),
                      // Email
                      CustomTextField(
                        hintText: "Email",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.h),
                      // Phone Number
                      CustomTextField(
                        hintText: "Phone number",
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length < 10) {
                            return 'Phone number must be at least 10 digits';
                          }
                          return null;
                        },
                      ),
                      if (widget.driver == null) ...[
                        SizedBox(height: 10.h),
                        // Password (only for new drivers)
                        CustomTextField(
                          hintText: "Password",
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10.h),
                        // Confirm Password (only for new drivers)
                        CustomTextField(
                          hintText: "Confirm Password",
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      SizedBox(height: 20.h),
                      // Save Button
                      const CustomAlert(alertKey: 'signup'),
                      PrimaryButton(
                        text: "Save",
                        onPressed: (){
                          if (_formKey.currentState!.validate() && selectedTitle != null) {
                          registerUser(selectedTitle!,_firstNameController.text,_lastNameController.text,_emailController.text,_phoneController.text,_passwordController.text,_confirmPasswordController.text);
                        } else if (selectedTitle == null) {
                          Alertify.showAlert(
                            alertKey: 'signup',
                            message: 'Please select a title',
                            type: AlertType.error,
                          );
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
    );
  }
}