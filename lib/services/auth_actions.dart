import 'package:flutter/material.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/routes/MyRoutes.dart';

/// Logs out everywhere: stops pushes to this phone (server), clears saved
/// login + in-memory user, and returns to the login selection screen.
Future<void> logoutAndGoToLogin(BuildContext context) async {
  try {
    await GeneralRepository()
        .logoutOnServer()
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // Offline or server error: still log out locally
  }
  ChatService.instance.stop(); // close chat connection + clear cached chats
  Globals.clearVariables();
  Globals.user = null;
  await SharedStorage.removeFromSharedPreferences();
  if (context.mounted) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(MyRoutes.selectionRoute, (route) => false);
  }
}

/// Employees and admins are staff: their accounts are managed by an admin.
bool get isStaffUser {
  final role = (Globals.user?.roleTitle ?? Globals.roleTitle).toLowerCase();
  return role == 'employee' || role == 'administrator';
}
