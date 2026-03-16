class ApiFiles {
  //**********************Grneral**********************/
  static String signin = "/api/auth/login";
  static String signup = "/api/auth/signup";
  static String bookingsList = "/api/booking/list";
  static String paymentHistoryList = "/api/payment/list";
  static String searchParking = "/api/search/v5";
  static String searchParking2 = "/api/search/v5";
  static String bookParking = "/api/booking/create";
  static String forgotPassword = "/api/auth/forgot/password";
  static String verifyEmail = "/api/auth/verify";
  static String createCheckpoint = "/api/booking/checkpoints/create";
  static String postLocation = "/api/booking/create/location";
  static String getLocationDetails = "/api/booking/detail/location";
  static String resetPassword = "/api/auth/reset/password";
  static String getDrivers = "/api/users/list/employees";
  static String assignDriver = "/api/booking/assignment/create";
  static String updateDriver = "/api/users/update";
  static String getNotifications = "/api/notification/list";
  static String markNotificationsAsRead = "/api/notification/update";
  static String clearAllNotifications = "/api/notification/delete";
  static String vehicleLookup = "/api/vechile/info";
  static String updateBooking = "/api/booking/update";
  static String updateProfileImage = "/api/users/update/image";
  static String updateProfileInfo = "/api/users/update";
  static String searchStatus = "/api/search/status";
  static String verifyPayment = "/api/stripe/verify-payment";
  static String dashboardData = "/api/dashboard/monthly-data";
  static String mainDashboardData = "/api/dashboard";
  static String searchByRegistration = "/api/upload/bookings/search";
  static String claimBooking = "/api/upload/bookings/claim";
}
