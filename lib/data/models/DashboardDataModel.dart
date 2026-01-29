class DashboardDataResponse {
  final bool success;
  final List<DashboardItem> data;

  DashboardDataResponse({required this.success, required this.data});

  factory DashboardDataResponse.fromJson(Map<String, dynamic> json) {
    return DashboardDataResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => DashboardItem.fromJson(item))
          .toList(),
    );
  }
}

class DashboardItem {
  final String name;
  final double currentRevenue;
  final double previousRevenue;
  final int currentUsers;
  final int previousUsers;

  DashboardItem({
    required this.name,
    required this.currentRevenue,
    required this.previousRevenue,
    required this.currentUsers,
    required this.previousUsers,
  });

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    return DashboardItem(
      name: json['name'] ?? '',
      currentRevenue: (json['currentRevenue'] ?? 0).toDouble(),
      previousRevenue: (json['previousRevenue'] ?? 0).toDouble(),
      currentUsers: json['currentUsers'] ?? 0,
      previousUsers: json['previousUsers'] ?? 0,
    );
  }
}
