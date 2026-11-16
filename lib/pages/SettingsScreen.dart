import 'package:parkingapp/data/Globals.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:parkingapp/data/api/api.dart';
import 'package:parkingapp/pages/ChangePasswordScreen.dart';
import 'package:parkingapp/services/auth_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: "Settings",
              showBackButton: false,
              onBackPressed: () => Navigator.pop(context),
              trailing: (Globals.user?.imageURL != null &&
                      Globals.user!.imageURL!.isNotEmpty)
                  ? GestureDetector(
                      onTap: () {
                        // Optional: Navigate to profile edit or show larger image
                      },
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundImage:
                            (Globals.user!.imageURL!.startsWith('http'))
                                ? NetworkImage(Globals.user!.imageURL!)
                                : FileImage(File(Globals.user!.imageURL!))
                                    as ImageProvider,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                children: [
                  _buildSectionTitle("General"),
                  _buildSettingItem(
                    "Edit Profile",
                    Icons.person_outline,
                    onTap: () async {
                      // Navigate to edit profile screen
                      await Navigator.pushNamed(context, MyRoutes.editProfile);
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  _buildSettingItem(
                    "Change Password",
                    Icons.lock_outline,
                    onTap: () {
                      // Logged in: change with current password.
                      // Not logged in: forgot-password (OTP) flow.
                      if (Globals.user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen()),
                        );
                      } else {
                        Navigator.pushNamed(context, MyRoutes.forgot);
                      }
                    },
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle("Term and Support"),
                  _buildSettingItem(
                    "Terms and conditions",
                    Icons.description_outlined,
                    onTap: () {
                      // Navigate to terms screen
                      Navigator.pushNamed(context, MyRoutes.termsAndCondition);
                    },
                  ),
                  _buildSettingItem(
                    "Help Center",
                    Icons.help_outline_outlined,
                    onTap: () {
                      // Navigate to support screen
                      Navigator.pushNamed(context, MyRoutes.supportRoute);
                    },
                  ),
                  _buildLogoutItem(context),
                  // Staff accounts are deactivated by an admin instead
                  if (Globals.user != null && !isStaffUser)
                    _buildDeleteAccountItem(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24.sp, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      trailing: Icon(Icons.chevron_right, size: 24.sp, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    String title,
    IconData icon,
    bool value, {
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24.sp, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colors.secondarynew,
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    if (Globals.user == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.login, size: 24.sp, color: colors.primaryNew),
        title: Text(
          "Login",
          style: TextStyle(fontSize: 16.sp, color: colors.primaryNew),
        ),
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(
              context, MyRoutes.selectionRoute, (route) => false);
        },
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.logout, size: 24.sp, color: Colors.red),
      title: Text(
        "Logout",
        style: TextStyle(fontSize: 16.sp, color: Colors.red),
      ),
      onTap: () async {
        // Confirm logout
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Logout", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          await logoutAndGoToLogin(context);
        }
      },
    );
  }

  Widget _buildDeleteAccountItem(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.delete_forever, size: 24.sp, color: Colors.red),
      title: Text(
        "Delete Account",
        style: TextStyle(fontSize: 16.sp, color: Colors.red),
      ),
      onTap: () async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Account"),
            content: const Text(
                "Are you sure you want to delete your account? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          try {
            EasyLoading.show(status: 'Deleting...');
            final api = API();
            final headers = {
              'access-token': Globals.user?.token ?? '',
              'Authorization': 'Bearer ${Globals.user?.token ?? ''}'
            };
            await api.sendRequest.post(
              '/api/users/delete',
              options: Options(headers: headers),
            );
            EasyLoading.dismiss();

            // Logout sequence
            Globals.clearVariables();

            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                MyRoutes.selectionRoute,
                (route) => false,
              );
            }
          } catch (e) {
            EasyLoading.dismiss();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "Failed to delete account. Please try again.")),
              );
            }
          }
        }
      },
    );
  }
}
