// Dart code for the new village addition screen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/config.dart';
import 'dart:convert';

class AddVillageScreen extends StatefulWidget {
  @override
  _AddVillageScreenState createState() => _AddVillageScreenState();
}

class _AddVillageScreenState extends State<AddVillageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController villageNameController = TextEditingController();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController rationCardController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String villageName = villageNameController.text;
      final String adminName = adminNameController.text;
      final String password = passwordController.text;
      final String phoneNumber = phoneNumberController.text;
      final String email = emailController.text;
      final String rationCard = rationCardController.text;
      String username = '';
      try {
        // Add Village to place collection
        var placeResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/add-place'),
          body: json.encode({"place_name": villageName}),
          headers: {'Content-Type': 'application/json'},
        );

        if (placeResponse.statusCode != 200) {
          throw Exception('Failed to add village.');
        }

        // Add admin user
        var userResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/add-admin-user'),
          body: json.encode({
            "name": adminName,
            "password": password,
            "phone": phoneNumber,
            "email": email,
            "address": villageName,
            "raID": rationCard,
          }),
          headers: {'Content-Type': 'application/json'},
        );
        var responseData = json.decode(userResponse.body);
        username = responseData['username'];
        if (userResponse.statusCode != 200) {
          throw Exception('Failed to add admin user.');
        }

        // Send email
        var emailResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/send-email'),
          body: json.encode({
            "name": adminName,
            "email": email,
            "place": villageName,
            "username": username,
            "password": password
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (emailResponse.statusCode != 200) {
          throw Exception('Failed to send email.');
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Village added successfully!')),
        );

        // Clear form fields and reset form state
        _formKey.currentState!.reset(); // Reset the form validation state
        villageNameController.clear();
        adminNameController.clear();
        passwordController.clear();
        phoneNumberController.clear();
        emailController.clear();
        rationCardController.clear();
        Navigator.pop(context, true); // Notify the calling page to refresh
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Village'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: villageNameController,
                decoration: InputDecoration(labelText: 'Village Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter village name' : null,
              ),
              TextFormField(
                controller: adminNameController,
                decoration: InputDecoration(labelText: 'Admin Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter admin name' : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter password';
                  } else if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Enter phone number' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: rationCardController,
                decoration: InputDecoration(labelText: 'Ration Card Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter ration card number' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF55947E), // Background color
                  minimumSize: Size(100, 50), // Set the width and height
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Color(0xFF001F14), // Text color
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
