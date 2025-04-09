import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                  _buildSettingItem("Edit Profile", Icons.person_outline),
                  _buildSettingItem("Change Password", Icons.lock_outline),
                  _buildSettingItem("Change Language", Icons.language_outlined),
                  _buildSettingItem("Change Location", Icons.location_on_outlined),
                  
                  SizedBox(height: 24.h),
                  _buildSectionTitle("Notifications"),
                  _buildSwitchItem("Turn on", Icons.notifications_outlined, true),
                  
                  SizedBox(height: 24.h),
                  _buildSectionTitle("Term and Support"),
                  _buildSettingItem("Terms and conditions", Icons.description_outlined),
                  _buildSettingItem("Privacy Policy", Icons.privacy_tip_outlined),
                  _buildSettingItem("Support", Icons.help_outline_outlined),
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

  Widget _buildSettingItem(String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24.sp, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      trailing: Icon(Icons.chevron_right, size: 24.sp, color: Colors.grey),
      onTap: () {
        // Handle item tap
      },
    );
  }

  Widget _buildSwitchItem(String title, IconData icon, bool value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24.sp, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      trailing: Switch(
        value: value,
        onChanged: (bool newValue) {
          // Handle switch toggle
        },
        activeColor: const Color(0xFF201A56),
      ),
    );
  }
}