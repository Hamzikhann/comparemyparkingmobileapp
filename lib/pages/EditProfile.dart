import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/CustomDropdown.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/PrimaryButton.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTitle;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // You might want to show an error message to the user
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    firstNameController.text = Globals.user!.firstName;
    lastNameController.text = Globals.user!.lastName;
    emailController.text = Globals.user!.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Edit Profile',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),

                        // Circular Avatar with Edit Icon
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120.w,
                              height: 120.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _pickedImage != null
                                    ? Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60.sp,
                                        color: Colors.grey.shade400,
                                      ),
                              ),
                            ),
                            Container(
                              width: 36.w,
                              height: 36.h,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18.sp,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: _showImageSourceBottomSheet,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Title Dropdown
                        CustomDropdown(
                          hint: "Title",
                          items: const ["Mr", "Mrs", "Do not want to Specify"],
                          isSearchable: false,
                          defaultValue: "Mr",
                          onSelectItem: (item) {
                            setState(() {
                              selectedTitle = item;
                            });
                          },
                        ),

                        SizedBox(height: 20.h),

                        // First Name
                        CustomTextField(
                          hintText: "First Name",
                          controller: firstNameController,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Last Name
                        CustomTextField(
                          hintText: "Last Name",
                          controller: lastNameController,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Email
                        CustomTextField(
                          hintText: "Email",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Phone Number
                        CustomTextField(
                          hintText: "Phone number",
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Phone number must be at least 10 digits';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),
                        const CustomAlert(alertKey: 'editProfile'),

                        // Save Button
                        PrimaryButton(
                          text: "Save",
                          onPressed: () {
                            if (_formKey.currentState!.validate() &&
                                selectedTitle != null) {
                              // registerUser(selectedTitle!,firstNameController.text,lastNameController.text,emailController.text,phoneController.text,passwordController.text,confirmPasswordController.text);
                            } else if (selectedTitle == null) {
                              Alertify.showAlert(
                                alertKey: 'editProfile',
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
            ),
          ],
        ),
      ),
    );
  }
}
