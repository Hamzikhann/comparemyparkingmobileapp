import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/admin/AddEditDriverScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';
import 'package:parkingapp/utils/colors.dart';

class DriverListScreen extends StatefulWidget {
  @override
  _DriverListScreenState createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<Driver> drivers = [];
  bool isLoading = true;
  String? errorMessage;
  final String screenTitle = "Drivers"; // Added title for the screen

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await GeneralRepository().getEmployeesWithBookings();
      final employeesData = response['data'] as List;

      setState(() {
        drivers = employeesData.map((json) => Driver.fromJson(json)).toList();
        Globals.drivers = drivers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load drivers: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void deleteDriver(String driverId) async {
    // TODO: Implement delete API call
    // await GeneralRepository().deleteDriver(driverId);
    fetchDrivers(); // Refresh list
  }

  void editDriver(Driver driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDriverScreen(driver: driver),
      ),
    ).then((_) => fetchDrivers());
  }

  void addDriver() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditDriverScreen()),
    ).then((_) => fetchDrivers());
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(  // Wrap with SafeArea
      child: Column(
        children: [
          TopBar(
            title: "Drivers",
            onBackPressed: () => Navigator.pop(context),
            onLogoutPressed: () {
              Globals.user = null;
              SharedStorage.removeFromSharedPreferences();
              Navigator.of(context).pushNamedAndRemoveUntil(
                MyRoutes.loginRoute, 
                (route) => false
              );
            },
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: addDriver,
      child: Icon(Icons.add),
    ),
  );
}

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (drivers.isEmpty) {
      return Center(child: Text("No drivers found"));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
                backgroundColor: Colors.blue[100],
              ),
              title: Text(driver.name),
              subtitle: Text(driver.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => editDriver(driver),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteDriver(driver.id),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Bookings:', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (driver.bookingAssignments.isEmpty)
                        Text('No bookings assigned'),
                      ...driver.bookingAssignments.map((assignment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Booking ID: ${assignment.bookingId}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // slightly increased for readability
                                  color: colors.blueDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 16),
                            Chip(
                              label: Text(
                                assignment.status,
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: _getStatusColor(assignment.status),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue[100];
      case 'completed':
        return Colors.green[100];
      case 'cancelled':
        return Colors.red[100];
      default:
        return Colors.grey[200];
    }
  }
}