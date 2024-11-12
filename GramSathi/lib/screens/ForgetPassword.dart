import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        height:
                            70), // Adjust top space to position text correctly
                    Text(
                      "Forgot Your Password",
                      style: GoogleFonts.roboto(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      _isOtpSent
                          ? (_isOtpVerified
                              ? "Your New Password Must Be Different from Previously Used Password."
                              : "Enter the 6-Digit Code Sent to ${_usernameController.text}")
                          : "Don\'t worry enter your registered username to recieve verification code",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 16, color: Colors.grey[500]),
                    ),
                    SizedBox(height: 35),
                    _buildIllustration(),
                    SizedBox(height: 20),
                    if (!_isOtpSent) _buildUserNameField(),
                    if (_isOtpSent && !_isOtpVerified) _buildOtpFields(),
                    if (_isOtpVerified) _buildPasswordFields(),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : _buildActionButton(),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_isOtpSent && !_isOtpVerified)
                      TextButton(
                        onPressed:
                            () {}, // Add your resend OTP functionality here
                        child: Text(
                          "Resend OTP?",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 6,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Column(
      children: [
        SizedBox(height: 20), // Added padding to push down the illustration
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 25,
                blurRadius: 45,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Image.asset(
            _isOtpSent
                ? (_isOtpVerified
                    ? 'assets/images/resetpassword.png'
                    : 'assets/images/verifyotp.png')
                : 'assets/images/forgetpw.png',
            height: 300,
          ),
        ),
        SizedBox(height: 100),
      ],
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
              counterText: "", // Hides the '0/1' counter below each text field
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF015F3E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF015F3E)),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            onChanged: (value) {
              if (value.length == 1 && index < _otpControllers.length - 1) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildUserNameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        hintText: 'Enter your registered username',
        labelStyle: TextStyle(color: Color(0xFF015F3E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF015F3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF015F3E)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      cursorColor: Color(0xFF015F3E),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'New Password',
            labelStyle: TextStyle(color: Color(0xFF015F3E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF015F3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF015F3E)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          cursorColor: Color(0xFF015F3E),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            labelStyle: TextStyle(color: Color(0xFF015F3E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF015F3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF015F3E)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          cursorColor: Color(0xFF015F3E),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isOtpSent
          ? (_isOtpVerified ? _resetPassword : _verifyOtp)
          : _sendOtp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF015F3E),
        padding: EdgeInsets.symmetric(vertical: 13, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        _isOtpSent
            ? (_isOtpVerified ? "Reset Password" : "Verify OTP")
            : "Send OTP",
        style: TextStyle(fontSize: 15, color: Colors.white),
      ),
    );
  }
}
