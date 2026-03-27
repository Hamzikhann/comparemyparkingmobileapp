import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
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
  final GeneralRepository _repository = GeneralRepository();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
        // Auto-upload image as per user request flow usually
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      EasyLoading.show(status: 'Uploading image...');
      final response =
          await _repository.updateProfileImage(Globals.user!.id, imageFile);

      // Check if response contains the new image URL
      if (response != null && response['data'] != null) {
        // Robust parsing of imageUrl from response
        String? newImageUrl;
        if (response['data'] is Map) {
          // Prioritize explicit matches
          newImageUrl = response['data']['imageurl'] ??
              response['data']['image'] ??
              response['data']['userProfile']?['image'] ??
              (response['data']['user'] is Map
                  ? (response['data']['user']['userProfile']?['image'] ??
                      response['data']['user']['image'])
                  : null);

          // Fallback to CamelCase matches
          newImageUrl ??= response['data']['imageURL'] ??
              response['data']['imageUrl'] ??
              response['data']['userProfile']?['imageURL'] ??
              response['data']['userProfile']?['imageUrl'] ??
              (response['data']['user'] is Map
                  ? (response['data']['user']['userProfile']?['imageURL'] ??
                      response['data']['user']['userProfile']?['imageUrl'] ??
                      response['data']['user']['imageURL'] ??
                      response['data']['user']['imageUrl'])
                  : null);
        }

        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          // Prepend base URL if relative (and not a local path)
          if (!newImageUrl.startsWith('http') && !newImageUrl.startsWith('/')) {
            newImageUrl =
                "https://comparemyairportparking.com/api/$newImageUrl";
          }

          // Force a cache-breaker to ensure image refreshes if URL is the same
          if (newImageUrl.startsWith('http')) {
            if (newImageUrl.contains('?')) {
              newImageUrl += "&t=${DateTime.now().millisecondsSinceEpoch}";
            } else {
              newImageUrl += "?t=${DateTime.now().millisecondsSinceEpoch}";
            }
          }

          setState(() {
            print("newImageUrl: $newImageUrl");
            Globals.user!.imageURL = newImageUrl;
          });

          // Save updated user to persistent storage
          await SharedStorage.saveUser(Globals.user!);
          EasyLoading.showSuccess('Image updated');
        } else {
          // Fallback: If API returns success but no URL, use local path
          // This allows "gallery selection" to persist at least for the session/device
          setState(() {
            print(
                "Fallback: Using locally picked image path: ${imageFile.path}");
            Globals.user!.imageURL = imageFile.path;
          });
          await SharedStorage.saveUser(Globals.user!);
          EasyLoading.showSuccess('Image updated');
        }
      } else {
        EasyLoading.showSuccess('Image updated');
      }
    } catch (e) {
      EasyLoading.showError('Image upload failed');
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      String fullName = fullNameController.text.trim();
      List<String> nameParts = fullName.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : "";
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

      Map<String, dynamic> data = {
        "title": "Mr", // Default title as not provided in UI fields
        "firstName": firstName,
        "lastName": lastName,
        "phoneNo": phoneController.text.trim(),
        "userId": Globals.user!.id,
      };

      try {
        await _repository.updateProfileInfo(data);

        // Update Globals and SharedStorage to reflect in app
        setState(() {
          Globals.user!.firstName = firstName;
          Globals.user!.lastName = lastName;
          Globals.user!.phoneNo = phoneController.text.trim();
        });

        await SharedStorage.saveUser(Globals.user!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        // Error already handled in repository
      }
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
    if (Globals.user != null) {
      fullNameController.text =
          "${Globals.user!.firstName} ${Globals.user!.lastName}".trim();
      emailController.text = Globals.user!.email;
      phoneController.text = Globals.user!.phoneNo;
    } else {
      fullNameController.text = "Guest User";
      emailController.text = "guest@example.com";
      phoneController.text = "";
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
              greeting: 'User Profile',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context, true),
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
                                        : (Globals.user?.imageURL != null &&
                                                Globals
                                                    .user!.imageURL!.isNotEmpty)
                                            ? (Globals.user!.imageURL!
                                                    .startsWith('http')
                                                ? NetworkImage(
                                                    Globals.user!.imageURL!)
                                                : FileImage(File(Globals
                                                        .user!.imageURL!))
                                                    as ImageProvider)
                                            : const AssetImage(
                                                'assets/images/user.png'),
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
                              if (Globals.user != null)
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
                                            color:
                                                Colors.black.withOpacity(0.1),
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
                        if (Globals.user != null)
                          PrimaryButton(
                            text: "Save",
                            onPressed: _handleSave,
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
          readOnly: Globals.user == null,
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
