import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/widgets/TopBar.dart';

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
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                children: [
                  _buildSectionTitle("General"),
                  _buildSettingItem(
                    "Edit Profile",
                    Icons.person_outline,
                    onTap: () {
                      // Navigate to edit profile screen
                      Navigator.pushNamed(context, MyRoutes.editProfile);
                    },
                  ),
                  _buildSettingItem(
                    "Change Password",
                    Icons.lock_outline,
                    onTap: () {
                      // Navigate to change password screen
                      Navigator.pushNamed(context, MyRoutes.forgot);
                    },
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle("Notifications"),
                  _buildSwitchItem(
                    "Turn on",
                    Icons.notifications_outlined,
                    true,
                    onChanged: (value) {
                      // Handle notification toggle
                      // You might want to save this preference to SharedPreferences
                      debugPrint(
                          "Notifications turned ${value ? 'on' : 'off'}");
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
                    "Privacy Policy",
                    Icons.privacy_tip_outlined,
                    onTap: () {
                      // Navigate to privacy policy screen
                      Navigator.pushNamed(context, MyRoutes.privacyPolicy);
                    },
                  ),
                  _buildSettingItem(
                    "Support",
                    Icons.help_outline_outlined,
                    onTap: () {
                      // Navigate to support screen
                      Navigator.pushNamed(context, MyRoutes.supportRoute);
                    },
                  ),
                  _buildLogoutItem(context),
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
        activeColor: const Color(0xFF201A56),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
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

        if (shouldLogout == true) {
          await SharedStorage.removeFromSharedPreferences();
          Navigator.of(context)
              .pushNamedAndRemoveUntil(MyRoutes.loginRoute, (route) => false);
        }
      },
    );
  }
}
