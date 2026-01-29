class AdminDashboardResponse {
  final bool success;
  final AdminDashboardData data;

  AdminDashboardResponse({required this.success, required this.data});

  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json) {
    return AdminDashboardResponse(
      success: json['success'] ?? false,
      data: AdminDashboardData.fromJson(json['data'] ?? {}),
    );
  }
}

class AdminDashboardData {
  final DashboardStats stats;
  final UserDistribution userDistribution;

  AdminDashboardData({required this.stats, required this.userDistribution});

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      userDistribution:
          UserDistribution.fromJson(json['userDistribution'] ?? {}),
    );
  }
}

class DashboardStats {
  final int totalUsers;
  final int totalBookings;
  final String totalPayments;
  final int pendingRequests;

  DashboardStats({
    required this.totalUsers,
    required this.totalBookings,
    required this.totalPayments,
    required this.pendingRequests,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      totalPayments: json['totalPayments']?.toString() ?? "0",
      pendingRequests: json['pendingRequests'] ?? 0,
    );
  }
}

class UserDistribution {
  final int active;
  final int inactive;
  final int newUsers;

  UserDistribution({
    required this.active,
    required this.inactive,
    required this.newUsers,
  });

  factory UserDistribution.fromJson(Map<String, dynamic> json) {
    return UserDistribution(
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      newUsers: json['new'] ?? 0,
    );
  }
}
