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
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    SizedBox(height: 25),
                    buildTextField(
                        'Village Name',
                        villageNameController,
                        (value) =>
                            value!.isEmpty ? 'Enter village name' : null),
                    buildTextField('Admin Name', adminNameController,
                        (value) => value!.isEmpty ? 'Enter admin name' : null),
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
                    buildTextField('Phone Number', phoneNumberController,
                        (value) => value!.isEmpty ? 'Enter phone number' : null,
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
                        onPressed: () {},
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
          )
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
