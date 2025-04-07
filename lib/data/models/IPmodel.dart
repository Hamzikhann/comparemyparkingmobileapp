class IPmodel {
  String ip;

  IPmodel({
    required this.ip,
  }) {
    // Add http:// if not present
    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      ip = 'http://$ip';
    }
  }

  factory IPmodel.fromJson(Map<String, dynamic> json) {
    return IPmodel(
      ip: json['IP'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IP': ip,
    };
  }
}
