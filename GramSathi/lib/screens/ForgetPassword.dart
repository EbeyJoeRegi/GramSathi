import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class ForgetPw extends StatefulWidget {
  @override
  _ForgetPwState createState() => _ForgetPwState();
}

class _ForgetPwState extends State<ForgetPw> {
  final TextEditingController _usernameController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  String _errorMessage = '';
  bool _isLoading = false;
  String? phoneNumber;

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/forgetpw'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': _usernameController.text}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _isOtpSent = true;
          phoneNumber = responseData['phoneNumber'];
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final otp = _otpControllers.map((controller) => controller.text).join();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _isOtpVerified = true;
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'OTP verification failed';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validatePassword(String password) {
    final passwordPattern =
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordPattern.hasMatch(password);
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match!';
      });
      return;
    }

    if (!_validatePassword(_newPasswordController.text)) {
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters long, contain letters, numbers, and special characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset successfully!")),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Password reset failed';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImage() {
    String imagePath;
    if (!_isOtpSent) {
      imagePath = 'assets/images/forgetpw.png';
    } else if (!_isOtpVerified) {
      imagePath = 'assets/images/verifyotp.png';
    } else {
      imagePath = 'assets/images/resetpassword.png';
    }

    return Stack(
      alignment: Alignment.center, // Center the image over the background
      children: [
        Container(
          width: 350, // Width of the circular background
          height: 350, // Height of the circular background
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD1E7A6)
                .withOpacity(0.7), // Light green with reduced opacity
          ),
        ),
        ClipOval(
          child: Image.asset(
            imagePath,
            height: 250, // Adjust the height as needed
            fit: BoxFit.cover, // Adjust image fit
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          _isOtpSent
              ? (_isOtpVerified
                  ? "Create New Password"
                  : "Verify Your Phone Number")
              : "Forgot Password",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        color: Colors.white, // Ensure the body has a white background
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: [
                _buildImage(),
                SizedBox(height: 20),

                // Step-specific Instructions
                Text(
                  _isOtpSent
                      ? (_isOtpVerified
                          ? "Your New Password Must Be Different from Previously Used Password."
                          : "Enter The 6 Digit Code Sent To ${_usernameController.text}")
                      : "Enter Your username To Receive a Verification Code.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 18), // Increased font size
                ),
                SizedBox(height: 30),

                // Input Fields
                if (!_isOtpSent) _buildUserNameField(),
                if (_isOtpSent && !_isOtpVerified) _buildOtpFields(),
                if (_isOtpVerified) _buildPasswordFields(),

                SizedBox(height: 30),
                _isLoading ? CircularProgressIndicator() : _buildActionButton(),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserNameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'UserName',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 40,
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: TextField(
            controller: _otpControllers[index],
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              counterText: '', // Hide the counter text
            ),
            keyboardType: TextInputType.number,
            maxLength: 1, // Limit to one character
            textAlign: TextAlign.center,
            onChanged: (value) {
              // Automatically move to the next text field
              if (value.length == 1 && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                // Move back to the previous field if current is empty
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isOtpSent
          ? (_isOtpVerified ? _resetPassword : _verifyOtp)
          : _sendOtp,
      child: Text(_isOtpSent
          ? (_isOtpVerified ? 'Reset Password' : 'Verify OTP')
          : 'Send OTP'),
    );
  }
}
