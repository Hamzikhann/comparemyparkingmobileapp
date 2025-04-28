import 'package:flutter/material.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/pages/admin/AddEditDriverScreen.dart';

class DriverListScreen extends StatefulWidget {
  @override
  _DriverListScreenState createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<Driver> drivers = []; // Assume Driver model

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    // TODO: Call your API here
    // Example: List<Driver> fetchedDrivers = await ApiService.getDrivers();
    setState(() {
      // drivers = fetchedDrivers;
    });
  }

  void deleteDriver(String driverId) async {
    // TODO: Call delete API
    //await ApiService.deleteDriver(driverId);
    fetchDrivers(); // Refresh list
  }

  void editDriver(Driver driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditDriverScreen(driver: driver)),
    ).then((_) => fetchDrivers()); // After edit, refresh
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
      appBar: AppBar(title: Text("Driver")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: drivers.isEmpty
            ? Center(child: Text("No drivers found"))
            : ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text(driver.name ?? "Unknown"),
                      subtitle: Text("Driver information"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deleteDriver(driver.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => editDriver(driver),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addDriver,
        child: Icon(Icons.add),
      ),
    );
  }
}
