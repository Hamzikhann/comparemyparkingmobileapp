class ApiFiles {
  //**********************Grneral**********************/
  static String signin = "/api/auth/login";
  static String signup = "/api/auth/signup";
  static String bookingsList = "/api/booking/list";
  static String paymentHistoryList = "/api/payment/list";
  static String searchParking = "/api/search/v5";
  // + "/<packageId>"; full package content, as the website's package-details page
  static String packageDetails = "/api/search/v5/package";
  static String siteConfig = "/api/site-config";
  // Checkout sign-up without a password (logs an existing customer email in), as the website
  static String guestSignup = "/api/auth/v1/signup";
  static String bookParking = "/api/booking/create";
  static String forgotPassword = "/api/auth/forgot/password";
  static String verifyEmail = "/api/auth/verify";
  static String createCheckpoint = "/api/booking/checkpoints/create";
  static String postLocation = "/api/booking/create/location";
  static String getLocationDetails = "/api/booking/detail/location";
  static String resetPassword = "/api/auth/reset/password";
  static String getDrivers = "/api/users/list/employees";
  static String logout = "/api/users/logout";
  static String saveFcmToken = "/api/users/fcm-token";
  // Admin app paged lists ({ limit, offset, search, ... } -> { rows, total })
  static String adminPaymentsList = "/api/payment/admin/list";
  static String adminUsersList = "/api/users/list";
  // Admin actions, same as the website admin Bookings / Users pages
  static String bookingDetail = "/api/booking/detail";
  static String adminBookingUpdate = "/api/booking/update/data";
  static String adminBookingEmail = "/api/booking/sendemail";
  static String adminUserCreate = "/api/users/create";
  static String adminUserUpdate = "/api/users/update";
  static String adminUserDeactivate = "/api/users/deactivate";
  // Forgot password in the app: emailed 6-digit code, then a new password
  static String resetCodeSend = "/api/auth/v2/forgot/password";
  static String resetCodeVerify = "/api/auth/v2/forgot/verify";
  static String resetCodeNewPassword = "/api/auth/v2/reset/password";
  static String changePassword = "/api/users/update/password";
  static String deactivateEmployee = "/api/users/deactivate";
  static String reassignDriver = "/api/booking/assignment/update";
  static String assignDriver = "/api/booking/assignment/create";
  static String updateDriver = "/api/users/update";
  static String getNotifications = "/api/notification/list";
  static String markNotificationsAsRead = "/api/notification/update";
  static String clearAllNotifications = "/api/notification/delete";
  static String vehicleLookup = "/api/vechile/info";
  static String updateBooking = "/api/booking/update";
  static String bookingChangePaymentIntent = "/api/booking/change/payment-intent";
  static String updateProfileImage = "/api/users/update/image";
  static String updateProfileInfo = "/api/users/update";
  static String verifyPayment = "/api/stripe/verify-payment";
  static String dashboardData = "/api/dashboard/monthly-data";
  static String mainDashboardData = "/api/dashboard";
  static String searchByRegistration = "/api/upload/bookings/search";
  static String claimBooking = "/api/upload/bookings/claim";
}
