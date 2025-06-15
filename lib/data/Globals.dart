import 'package:parkingapp/data/models/BookingInfoModel.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/models/IPmodel.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/models/SignupModel.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';

class Globals {
  static int selectedFilter = 1;
  static String startDate = "";
  static String endDate = "";
  static String startTime = "";
  static String endTime = "";
  static String selectedDateRange = "";
  static String detailType = "";
  static String roleTitle = "";
  static String emailReset = "";
  static String otp = "";
  static String passwordReset = "";
  static String confirmPassword = "";
  static List<Parking> reservedParkings = [];
  //**********User**********
  static UserModel? user;
  static IPmodel? ip;
  //**********User**********
  static ParkingOption? option;
  static BookingInfoModel? booking_info_model;
  static Parking? bookingDriverResponse;
  static UserSignup? userSignup;
  static Parking? bookingdetailuser;
  static List<Driver> drivers = [];

  //**********clear**********
  static void clearVariables() {
    user = null;
    SharedStorage.removeFromSharedPreferences();
  }
}
