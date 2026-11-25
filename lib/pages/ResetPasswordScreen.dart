import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/services/push_token.dart';
import 'package:parkingapp/widgets/CustomTextField.dart';

/// Forgot password (app): email -> 6-digit code from the email -> new password,
/// then the user is logged straight in.
class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum _Step { email, code, password }

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _green = Color(0xFF4B725D);
  static const _dark = Color(0xFF1A1A2E);

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repo = GeneralRepository();

  _Step _step = _Step.email;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;
  String _resetToken = '';
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail.trim();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    await _run(() async {
      final message = await _repo.sendPasswordResetCode(_email);
      if (!mounted) return;
      _codeController.clear();
      setState(() {
        _step = _Step.code;
        _info = message;
      });
      _startResendTimer();
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code from the email.');
      return;
    }
    await _run(() async {
      _resetToken = await _repo.verifyPasswordResetCode(_email, code);
      if (!mounted) return;
      setState(() {
        _step = _Step.password;
        _info = null;
      });
    });
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password.length > 64) {
      setState(() => _error = 'Password must be 64 characters or fewer.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    await _run(() async {
      final user = await _repo.resetPasswordWithCode(_resetToken, password);
      // The web version is for employees only: don't log anyone else in
      if (kIsWeb && user.roleTitle != "Employee") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Password changed. This web version is for staff only, so please log in on the mobile app or the website.')));
        Navigator.of(context)
            .pushNamedAndRemoveUntil(MyRoutes.selectionRoute, (r) => false);
        return;
      }
      Globals.user = user;
      Globals.roleTitle = user.roleTitle;
      PushToken.sync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Password changed. You're now logged in.")));
      final route = user.roleTitle == "Employee"
          ? MyRoutes.driverhome
          : MyRoutes.mainPage;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == _Step.code && !_busy) {
              setState(() {
                _step = _Step.email;
                _error = null;
                _info = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (_step) {
                  _Step.email => 'Forgot your\npassword?',
                  _Step.code => 'Check your\nemail',
                  _Step.password => 'Set a new\npassword',
                },
                style: TextStyle(
                  fontSize: 28.sp,
                  fontFamily: 'Archivo',
                  color: _dark,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                switch (_step) {
                  _Step.email =>
                    "Enter the email you use with us. We'll email you a 6-digit code.",
                  _Step.code => 'Enter the 6-digit code we sent to $_email.',
                  _Step.password =>
                    'Choose a new password (at least 8 characters).',
                },
                style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Archivo',
                    color: const Color(0xFF5C6670),
                    height: 1.4),
              ),
              SizedBox(height: 32.h),
              ..._fields(),
              if (_info != null && _step == _Step.code) ...[
                SizedBox(height: 12.h),
                Text(_info!,
                    style: TextStyle(
                        fontSize: 13.sp, fontFamily: 'Archivo', color: _green)),
              ],
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(_error!,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: 'Archivo',
                        color: Colors.red.shade700)),
              ],
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : switch (_step) {
                          _Step.email => _sendCode,
                          _Step.code => _verifyCode,
                          _Step.password => _savePassword,
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: _green.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          switch (_step) {
                            _Step.email => 'Send code',
                            _Step.code => 'Verify code',
                            _Step.password => 'Save and log in',
                          },
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: 'Archivo',
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (_step == _Step.code) ...[
                SizedBox(height: 16.h),
                Center(
                  child: TextButton(
                    onPressed: (_busy || _resendIn > 0) ? null : _sendCode,
                    child: Text(
                      _resendIn > 0
                          ? "Didn't get it? Resend in ${_resendIn}s"
                          : "Didn't get it? Resend code",
                      style: TextStyle(fontSize: 14.sp, fontFamily: 'Archivo'),
                    ),
                  ),
                ),
                Center(
                  child: Text('Also check your spam folder.',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'Archivo',
                          color: const Color(0xFF8A939B))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (_step) {
      case _Step.email:
        return [
          CustomTextField(
            labelText: 'Email',
            hintText: 'example@gmail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            useLightBackground: true,
          ),
        ];
      case _Step.code:
        return [
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
                fontSize: 26.sp, letterSpacing: 12, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              filled: true,
              fillColor: const Color(0xFFF5F7F6),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _busy ? null : _verifyCode(),
          ),
        ];
      case _Step.password:
        final eye = IconButton(
          icon: Icon(
              _showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF414141),
              size: 22.sp),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        );
        return [
          CustomTextField(
            labelText: 'New password',
            hintText: '••••••••••',
            controller: _passwordController,
            obscureText: !_showPassword,
            useLightBackground: true,
            suffixIcon: eye,
          ),
          SizedBox(height: 24.h),
          CustomTextField(
            labelText: 'Confirm new password',
            hintText: '••••••••••',
            controller: _confirmController,
            obscureText: !_showPassword,
            useLightBackground: true,
          ),
        ];
    }
  }
}
