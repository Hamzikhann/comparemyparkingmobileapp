import 'package:parkingapp/services/auth_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/CustomTextField.dart';
import 'package:parkingapp/widgets/PrimaryButton.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';

class AddEditDriverScreen extends StatefulWidget {
  final Driver? driver;

  const AddEditDriverScreen({Key? key, this.driver}) : super(key: key);

  @override
  State<AddEditDriverScreen> createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _titleOptions = ["Mr", "Mrs", "Do not want to Specify"];
  String? _selectedTitle;
  bool _isLoading = false;

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
      _selectedTitle = widget.driver!.title;
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTitle == null) {
      Alertify.showAlert(
        alertKey: 'driver_form',
        message: 'Please select a title',
        type: AlertType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.driver == null) {
        await _addNewDriver();
      } else {
        await _updateDriver();
      }

      await _refreshDriversList();
      
      Alertify.showAlert(
        alertKey: 'driver_form',
        message: widget.driver == null 
            ? 'Driver added successfully!' 
            : 'Driver updated successfully!',
        type: AlertType.success,
        duration: 2,
        onClose: () => Navigator.pop(context),
      );
    } catch (e) {
      Alertify.showAlert(
        alertKey: 'driver_form',
        message: e.toString(),
        type: AlertType.error,
        duration: 5,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewDriver() async {
    await GeneralRepository().signupv2(
      title: _selectedTitle!,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNo: _phoneController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  Future<void> _updateDriver() async {
    await GeneralRepository().updateDriver(
      title: _selectedTitle!,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNo: _phoneController.text,
      userId: widget.driver!.id,
    );
  }

  Future<void> _refreshDriversList() async {
    try {
      final response = await GeneralRepository().getEmployeesWithBookings();
      final employeesData = response['data'] as List;
      Globals.drivers = employeesData.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      print('Error refreshing drivers list: $e');
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
              onLogoutPressed: _handleLogout,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 24.h),
                      _buildTitleDropdown(),
                      SizedBox(height: 16.h),
                      _buildFirstNameField(),
                      SizedBox(height: 16.h),
                      _buildLastNameField(),
                      SizedBox(height: 16.h),
                      _buildEmailField(),
                      SizedBox(height: 16.h),
                      _buildPhoneField(),
                      if (widget.driver == null) ...[
                        SizedBox(height: 16.h),
                        _buildPasswordField(),
                        SizedBox(height: 16.h),
                        _buildConfirmPasswordField(),
                      ],
                      SizedBox(height: 24.h),
                      const CustomAlert(alertKey: 'driver_form'),
                      _buildSubmitButton(),
                      SizedBox(height: 24.h),
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

  Widget _buildTitleDropdown() {
    return CustomDropdown(
      hint: "Title",
      items: _titleOptions,
      isSearchable: false,
      defaultValue: _selectedTitle,
      onSelectItem: (item) => setState(() => _selectedTitle = item),
    );
  }

  Widget _buildFirstNameField() {
    return CustomTextField(
      hintText: "First Name",
      controller: _firstNameController,
      keyboardType: TextInputType.name,
      validator: (value) => value?.isEmpty ?? true ? 'Please enter first name' : null,
    );
  }

  Widget _buildLastNameField() {
    return CustomTextField(
      hintText: "Last Name",
      controller: _lastNameController,
      keyboardType: TextInputType.name,
      validator: (value) => value?.isEmpty ?? true ? 'Please enter last name' : null,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      hintText: "Email",
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter email';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return CustomTextField(
      hintText: "Phone number",
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter phone number';
        if (value!.length < 10) return 'Phone number must be at least 10 digits';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      hintText: "Password",
      controller: _passwordController,
      obscureText: true,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter a password';
        if (value!.length < 8) return 'Password must be at least 8 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return CustomTextField(
      hintText: "Confirm Password",
      controller: _confirmPasswordController,
      obscureText: true,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please confirm password';
        if (value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
  return PrimaryButton(
    text: _isLoading ? "Processing..." : "Save",
    onPressed: () { _handleSubmit(); },
  );
}

  // Same logout as everyone else: stops this phone's pushes, clears chats
  void _handleLogout() => logoutAndGoToLogin(context);
}
