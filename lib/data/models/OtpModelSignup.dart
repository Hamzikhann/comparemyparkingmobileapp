class OtpmodelSignup {
  String otp;

  OtpmodelSignup
({
    required this.otp,
  });

  factory OtpmodelSignup
.fromJson(Map<String, dynamic> json) {
    return OtpmodelSignup
  (
      otp: json['otp']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otp': otp,
    };
  }
}
