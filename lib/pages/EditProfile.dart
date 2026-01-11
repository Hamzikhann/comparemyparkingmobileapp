import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/widgets/CustomAlert.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import '../widgets/PrimaryButton.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
    fullNameController.text =
        "${Globals.user!.firstName} ${Globals.user!.lastName}".trim();
    emailController.text = Globals.user!.email;
    phoneController.text = Globals.user!.phoneNo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'User Profile',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),

                        // Avatar Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: _pickedImage != null
                                        ? FileImage(File(_pickedImage!.path))
                                        : const AssetImage(
                                                'assets/images/profilee.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Green status dot
                              Positioned(
                                top: 5.h,
                                right: 5.w,
                                child: Container(
                                  width: 14.w,
                                  height: 14.w,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF4B725D), // Green color
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                              // Edit Icon
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImageSourceBottomSheet,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        _buildProfileField("Full name", fullNameController),
                        SizedBox(height: 24.h),
                        _buildProfileField("Email address", emailController,
                            keyboardType: TextInputType.emailAddress),
                        SizedBox(height: 24.h),
                        _buildProfileField("Phone number", phoneController,
                            keyboardType: TextInputType.phone),

                        SizedBox(height: 40.h),

                        const CustomAlert(alertKey: 'editProfile'),

                        // Save Button
                        PrimaryButton(
                          text: "Save",
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Handle save logic
                              // Split full name if needed
                            }
                          },
                          // Assuming PrimaryButton uses the primary theme color (green)
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

  Widget _buildProfileField(String label, TextEditingController controller,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Archivo',
            color: const Color(0xFF9E9E9E), // Grey color for label
            fontWeight: FontWeight.w400,
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16.sp,
            fontFamily: 'Archivo',
            color: const Color(0xFF1A1A2E), // Darker color for value
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4B725D)),
            ),
          ),
        ),
      ],
    );
  }
}
