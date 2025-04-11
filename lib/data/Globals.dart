import 'package:parkingapp/data/models/IPmodel.dart';
import 'package:parkingapp/data/models/UserModel.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';

class Globals {
  static int selectedFilter = 1;
  static String startDate = "";
  static String endDate = "";
  static String startTime = "";
  static String endTime = "";
  static String selectedDateRange = "";

  
  //**********User**********
  static UserModel? user;
  static IPmodel? ip;

  //**********clear**********
  static void clearVariables() {
    user = null;
    SharedStorage.removeFromSharedPreferences();
  }
}
