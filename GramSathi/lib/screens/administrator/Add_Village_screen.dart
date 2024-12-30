import 'dart:convert';
import '/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
  bool isLoading = false;

  // Function to clear text fields
  void clearFields() {
    villageNameController.clear();
    adminNameController.clear();
    passwordController.clear();
    phoneNumberController.clear();
    emailController.clear();
    rationCardController.clear();
  }

  // Function to handle form submission
  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      String villageName = villageNameController.text;
      String adminName = adminNameController.text;
      String password = passwordController.text;
      String phone = phoneNumberController.text;
      String email = emailController.text;
      String rationCard = rationCardController.text;

      try {
        // Step 1: Call /add-place API
        var placeResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/add-place'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'place_name': villageName}),
        );

        if (placeResponse.statusCode == 200) {
          // Step 2: Call /add-admin-user API
          var adminResponse = await http.post(
            Uri.parse('${AppConfig.baseUrl}/add-admin-user'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': adminName,
              'password': password,
              'phone': phone,
              'email': email,
              'address': villageName,
              'raID': rationCard,
            }),
          );

          if (adminResponse.statusCode == 200) {
            var adminData = json.decode(adminResponse.body);
            String username = adminData[
                'username']; // Assuming the username is in the response

            // Step 3: Call /send-email API
            var emailResponse = await http.post(
              Uri.parse('${AppConfig.baseUrl}/send-email'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'name': adminName,
                'place': villageName,
                'email': email,
                'username': username,
                'password': password,
              }),
            );

            if (emailResponse.statusCode == 200) {
              // Successfully submitted, clear the text fields
              clearFields();
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Village and admin added successfully!')),
              );
              Navigator.pop(context, true);
            } else {
              // Handle email sending failure
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send email.')),
              );
            }
          } else {
            // Handle add-admin-user failure
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add admin.')),
            );
          }
        } else {
          // Handle add-place failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add place.')),
          );
        }
      } catch (e) {
        // Handle network or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Village',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white, // Set the background color to white
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: SingleChildScrollView(
                // Add this widget to allow scrolling
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      buildTextField(
                          'Village Name',
                          villageNameController,
                          (value) =>
                              value!.isEmpty ? 'Enter village name' : null),
                      buildTextField(
                          'Admin Name',
                          adminNameController,
                          (value) =>
                              value!.isEmpty ? 'Enter admin name' : null),
                      buildTextField(
                        'Password',
                        passwordController,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter password';
                          } else if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                      buildTextField(
                          'Phone Number',
                          phoneNumberController,
                          (value) =>
                              value!.isEmpty ? 'Enter phone number' : null,
                          inputType: TextInputType.phone),
                      buildTextField('Email', emailController,
                          (value) => value!.isEmpty ? 'Enter email' : null,
                          inputType: TextInputType.emailAddress),
                      buildTextField(
                        'Ration Card Number',
                        rationCardController,
                        (value) =>
                            value!.isEmpty ? 'Enter ration card number' : null,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 40.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Color(0xFF015F3E),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      String? Function(String?) validator,
      {bool obscureText = false,
      TextInputType inputType = TextInputType.text}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black54, fontSize: 14),
          filled: true,
          fillColor: Color(0xffE6F4E3),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF015F3E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        obscureText: obscureText,
        keyboardType: inputType,
        validator: validator,
      ),
    );
  }
}
