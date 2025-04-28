import 'package:flutter/material.dart';
import 'package:parkingapp/data/models/Driver.dart';

class AddEditDriverScreen extends StatefulWidget {
  final Driver? driver;

  const AddEditDriverScreen({Key? key, this.driver}) : super(key: key);

  @override
  _AddEditDriverScreenState createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      _nameController.text = widget.driver!.name ?? '';
      _contactController.text = widget.driver!.contact ?? '';
      _emailController.text = widget.driver!.email ?? '';
      _licenseController.text = widget.driver!.licenseNumber ?? '';
      _expiryDateController.text = widget.driver!.expiryDate ?? '';
    }
  }

  void saveDriver() async {
    if (_formKey.currentState!.validate()) {
      if (widget.driver == null) {
        // Add new driver
        // await ApiService.addDriver(
        //   name: _nameController.text,
        //   contact: _contactController.text,
        //   email: _emailController.text,
        //   license: _licenseController.text,
        //   expiry: _expiryDateController.text,
        // );
      } else {
        // Update driver
        // await ApiService.updateDriver(
        //   driverId: widget.driver!.id,
        //   name: _nameController.text,
        //   contact: _contactController.text,
        //   email: _emailController.text,
        //   license: _licenseController.text,
        //   expiry: _expiryDateController.text,
        // );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.driver == null ? "Add Driver" : "Edit Driver")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Full Name"),
                validator: (value) => value!.isEmpty ? "Enter full name" : null,
              ),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: "Contact Number"),
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email Address"),
              ),
              TextFormField(
                controller: _licenseController,
                decoration: InputDecoration(labelText: "License Number"),
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(labelText: "Expiry Date"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                child: Text(
                  "Save",
                  style: TextStyle(color: Colors.white), // text color white
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
