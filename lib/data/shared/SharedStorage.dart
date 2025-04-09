import 'dart:convert';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/IPmodel.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedStorage {
  static const String userKey = 'user_data';
  static const String ipKey = 'ip_data';
  static const String themeKey = 'theme_data';
  static const String emailsKey = 'emails';

  static Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(userKey);

    if (jsonString != null) {
      final data = json.decode(jsonString);
      Globals.user =
          UserModel.fromJson(data); // pass full data, not data['user']
    }
  }

  static Future<void> saveUser(UserModel user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = {
      'user': user.toJson(), // Save user data as is
      'token': user.token, // Save token separately at the top level
    };

    final jsonString = json.encode(data);
    await prefs.setString(userKey, jsonString);
  }

  static Future<void> setIP(IPmodel ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = {
      'ip': ip.toJson(),
    };
    final jsonString = json.encode(data);

    await prefs.setString(ipKey, jsonString);
    Globals.ip = ip;
  }

  static Future<void> loadIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(ipKey);

    if (jsonString != null) {
      final data = json.decode(jsonString);
      Globals.ip = IPmodel.fromJson(data['ip']);
    }
  }

  static Future<void> saveTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDark);
  }

  static Future<bool> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? false;
  }

  static Future<void> saveEmails(List<String> emails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(emailsKey, emails);
  }

  static Future<List<String>> loadEmails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(emailsKey) ?? [];
  }

  static Future<void> removeFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    await prefs.remove(ipKey);
    await prefs.remove(themeKey);
    await prefs.remove(emailsKey);
  }
}
