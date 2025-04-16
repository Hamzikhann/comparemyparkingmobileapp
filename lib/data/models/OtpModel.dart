class Otpmodel {
  String otp;
  String token;

  Otpmodel({
    required this.otp,
    required this.token,
  });

  factory Otpmodel.fromJson(Map<String, dynamic> json) {
    return Otpmodel(
      otp: json['otp'],
      token: json[
          'token'], // token should come from the root of json, not from user
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otp': otp,
      'token': token,
    };
  }
}
