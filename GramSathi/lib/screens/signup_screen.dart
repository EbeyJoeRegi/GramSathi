import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/screens/login_screen.dart';
import 'dart:convert';
import 'package:gramsathi/config.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _rationCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpPhoneControllers =
      List.generate(6, (index) => TextEditingController());
  final TextEditingController _otpEmailController =
      TextEditingController(); // For OTP
  final List<TextEditingController> _otpEmailControllers =
      List.generate(6, (_) => TextEditingController());

  bool _isLoading = false;
  bool _isEmailOTPFieldVisible = false;
  bool _isOTPFieldVisible = false; // To show/hide OTP field
  String? _rationCardError;
  String? _phoneError;
  String? _passwordError;
  String? _emailError;
  List<String> _locations = [];
  String? _selectedLocation;
  String? _emailVerificationStatus; // To store verification status messages
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;
  String? _phoneVerificationStatus;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _fetchLocations(); // Fetch locations on initialization
  }

  Future<void> _fetchLocations() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/locations'));

      if (response.statusCode == 200) {
        final List<dynamic> locationsData = json.decode(response.body);
        setState(() {
          _locations = locationsData
              .map((location) => location['place_name'] as String)
              .toList();
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  // Function to send OTP using API (Twilio will be handled server-side)
  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _phoneError = null; // Reset error message
    });

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Replace with your actual API call
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/send-otp'),
        body: jsonEncode({'phoneNumber': phoneNumber}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Handle success
        setState(() {
          _isOTPFieldVisible = true;
          _isLoading = false;
        });
      } else {
        // Handle failure
        final responseBody = jsonDecode(response.body);
        setState(() {
          _phoneError =
              responseBody['error'] ?? 'Failed to send OTP. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _phoneError = 'Failed to send OTP. Please try again.';
        _isLoading = false;
      });
      print('Error sending OTP: $e'); // Log the error for debugging
    }
  }

  // Function to verify phone OTP
  Future<void> _verifyOTP() async {
    // Collect the OTP from each individual text field (assuming 6 fields)
    final otp = _otpPhoneControllers
        .map((controller) => controller.text)
        .join(); // Collect OTP digits
    final phone = _phoneController.text;

    // Validate the OTP length
    if (otp.length != 6) {
      setState(() {
        _phoneError =
            'OTP must be 6 digits.'; // Display error if OTP is incomplete
      });
      return;
    }

    try {
      // Send the OTP verification request to the server
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-otp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phoneNumber': phone,
          'otp': otp, // Use the concatenated OTP
        }),
      );

      // Handle the response from the server
      if (response.statusCode == 200) {
        setState(() {
          _isOTPFieldVisible =
              false; // Hide OTP input on successful verification
          _isPhoneVerified = true; // Mark phone as verified
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Verification Successful'),
            content: Text('Phone number verified successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _phoneError =
              'Invalid OTP. Please try again.'; // Error on invalid OTP
        });
      }
    } catch (e) {
      setState(() {
        _phoneError = 'Error verifying OTP.'; // Handle network or server errors
      });
    }
  }

  // Function to send OTP to email
  Future<void> _sendEmailOTP() async {
    setState(() {
      _isLoading = true;
      _emailError = null; // Reset error message
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/send-email-otp'),
        body: jsonEncode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEmailOTPFieldVisible = true; // Show the email OTP input
          _isLoading = false;
        });
      } else {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _emailError = responseBody['error'] ??
              'Failed to send email OTP. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _emailError = 'Failed to send email OTP. Please try again.';
        _isLoading = false;
      });
      print('Error sending email OTP: $e'); // Log the error for debugging
    }
  }

  // Function to verify email OTP
  Future<void> _verifyEmailOTP() async {
    String otp =
        _otpEmailControllers.map((controller) => controller.text).join();
    final email = _emailController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        _emailError = 'Invalid OTP. Please enter a valid 6-digit OTP.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-email-otp'),
        body: jsonEncode({'email': email, 'otp': otp}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // OTP is verified successfully, update the state
        setState(() {
          _isEmailVerified = true; // Mark email as verified
          _isEmailOTPFieldVisible = false; // Hide OTP fields
          _emailVerificationStatus =
              'Email Verified Successfully'; // Update status
        });

        // Show the verification successful dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Verification Successful'),
            content: Text('Email verified successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Optionally, you can reset the fields or perform further actions here
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _emailError = 'Invalid OTP. Please try again.';
        });
        // Log response details for debugging
        print('Error details: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _emailError = 'Error verifying email OTP: $e';
      });
      print('Error: $e'); // Log error message
    }
  }

  bool _validateFields() {
    bool isValid = true;

    // Validate Ration Card Number
    final rationCard = _rationCardController.text;
    if (rationCard.isEmpty) {
      setState(() {
        _rationCardError = 'Ration Card Number is required.';
      });
      isValid = false;
    } else {
      setState(() {
        _rationCardError = null;
      });
    }

    // Validate Password
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters long.';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    // Validate Phone Number
    final phone = _phoneController.text;
    final phoneRegExp = RegExp(r'^(?:\+91|91|0)?[789]\d{9}$');
    if (!phoneRegExp.hasMatch(phone)) {
      setState(() {
        _phoneError = 'Phone number must be exactly 10 digits.';
      });
      isValid = false;
    } else {
      setState(() {
        _phoneError = null;
      });
    }

    // Validate Email
    final email = _emailController.text;
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        _emailError = 'Invalid email format.';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    return isValid;
  }

  Future<void> _signup() async {
    if (!_validateFields() || !_isEmailVerified || !_isPhoneVerified) {
      return;
    }

    final rationCard = _rationCardController.text;
    final password = _passwordController.text;
    final name = _nameController.text;
    final phone = _phoneController.text;
    final email = _emailController.text;
    final jobTitle = _jobTitleController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'raID': rationCard,
          'name': name,
          'phone': phone,
          'email': email,
          'address': _selectedLocation ?? '', // Send selected location
          'jobTitle': jobTitle,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // Show success popup
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Signup Successful'),
            content: Text(responseBody['message']),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.pushReplacementNamed(
                      context, '/login'); // Redirect to login page
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final responseBody = json.decode(response.body);
        // Show error popup
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Signup Failed'),
            content: Text(responseBody['error'] ?? 'An error occurred.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Signup Failed'),
          content: Text('An error occurred. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _rationCardController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _otpController.dispose();
    _otpEmailController.dispose(); // Dispose OTP controller
    _animationController.dispose();
    for (var controller in _otpEmailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/bgvillage9.jpeg', // Replace with your image path
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black
                      .withOpacity(0.45), // Apply black color with opacity
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              top: 55.0,
              right: 24.0,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Sign Up',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 24),

                        // Name Text Field
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF57636C),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                    0xFFE0E3E7), // Border color when not focused
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(
                                    0xff015F3E), // Border color when focused
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            filled: true, // Ensure background color is applied
                            fillColor: Colors.white.withOpacity(
                                0.7), // Slightly transparent background
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 20),
                          ),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF101213),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 18),

                        // Email Field with Send OTP Button
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'Email Address',
                                      errorText: _emailError,
                                      hintStyle: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFE0E3E7),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xff015F3E),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.7),
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 19, horizontal: 20),
                                      isDense: true,
                                      suffixIcon: _isEmailVerified
                                          ? Icon(
                                              Icons.check_circle,
                                              color: Colors
                                                  .green, // Show green checkmark when verified
                                              size: 24,
                                            )
                                          : null, // No icon when not verified
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (email) {
                                      setState(() {
                                        _emailError =
                                            ''; // Reset error if user types a new email
                                        _isEmailVerified =
                                            false; // Reset email verification status
                                      });
                                    },
                                  ),

                                  // Positioned "Verify" button when email is not yet verified
                                  if (!_isEmailVerified)
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _sendEmailOTP, // Send OTP when the button is clicked
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          backgroundColor: Colors.greenAccent
                                              .withOpacity(0.8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          'Verify',
                                          style: TextStyle(
                                            color: Color(0xff015F3E),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 18),

// OTP Verification TextField for Email (Visible after sending OTP)
                        // OTP Verification TextField for Email (Visible after sending OTP)
                        if (_isEmailOTPFieldVisible)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Bring OTP boxes closer
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: 50, // Reduced width for closer boxes
                                    height: 50, // Height of each OTP box
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 4), // Margin between boxes
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Color(0xFFE0E3E7), width: 2),
                                      color: Colors.white.withOpacity(
                                          0.5), // Reduced transparency
                                    ),
                                    child: TextField(
                                      controller: _otpEmailControllers[index],
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '', // No hint text
                                        counterText:
                                            '', // Disable character counter
                                        hintStyle: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Color(0xFF57636C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 15), // Adjust padding
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF101213),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength:
                                          1, // Limiting to one character per box
                                      onChanged: (value) {
                                        // Logic for auto-focusing next box after entering a digit
                                        if (value.isNotEmpty) {
                                          if (index < 5) {
                                            FocusScope.of(context).nextFocus();
                                          } else {
                                            // If it's the last box, remove focus
                                            FocusScope.of(context).unfocus();
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: 10),

                              // Only show the Verify OTP button if email is NOT verified
                              if (!_isEmailVerified)
                                ElevatedButton(
                                  onPressed: _verifyEmailOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                  ),
                                  child: Text(
                                    'Verify Email OTP',
                                    style: TextStyle(color: Color(0xff015F3E)),
                                  ),
                                ),

                              // Display verification status
                              if (_emailVerificationStatus != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text(
                                    _emailVerificationStatus!,
                                    style: TextStyle(
                                      color: _isEmailVerified
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        SizedBox(
                          height: 15,
                        ),

                        // Password Text Field
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            errorText: _passwordError,
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF57636C)
                                  .withOpacity(0.7), // Opacity for hint text
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE0E3E7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff015F3E),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            filled: true,
                            fillColor: Colors.white
                                .withOpacity(0.7), // Opacity for the background
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 19, horizontal: 20),
                          ),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF101213)
                                .withOpacity(0.7), // Opacity for the input text
                            fontSize:
                                14, // Reduce font size for a more compact height
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 18),

                        // Ration Card Number Text Field
                        TextField(
                          controller: _rationCardController,
                          decoration: InputDecoration(
                            hintText: 'Ration Card Number',
                            errorText: _rationCardError,
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF57636C)
                                  .withOpacity(0.7), // Hint text opacity
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE0E3E7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff015F3E),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            filled: true,
                            fillColor: Colors.white
                                .withOpacity(0.7), // Background opacity
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 19, horizontal: 20),
                          ),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF101213)
                                .withOpacity(0.7), // Text opacity
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 18),

                        // Job Title Text Field
                        TextField(
                          controller: _jobTitleController,
                          decoration: InputDecoration(
                            hintText: 'Job Title',
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF57636C)
                                  .withOpacity(0.7), // Hint text opacity
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE0E3E7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff015F3E),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            filled: true,
                            fillColor: Colors.white
                                .withOpacity(0.7), // Background opacity
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 19, horizontal: 20),
                          ),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF101213)
                                .withOpacity(0.7), // Text opacity
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 18),

                        // Phone Number Field with Send OTP Button
                        // Phone Number TextField
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  TextField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      hintText: 'Phone Number',
                                      errorText: _phoneError,
                                      hintStyle: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color:
                                            Color(0xFF57636C).withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFE0E3E7),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xff015F3E),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.7),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 19,
                                        horizontal: 20,
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isPhoneVerified)
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 24,
                                            ),
                                          if (!_isPhoneVerified)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Positioned(
                                                left: 10,
                                                top: 10,
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _sendOTP,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10,
                                                            horizontal: 15),
                                                    backgroundColor: Colors
                                                        .greenAccent
                                                        .withOpacity(0.8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Verify',
                                                    style: TextStyle(
                                                      color: Color(0xff015F3E),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (phone) {
                                      setState(() {
                                        _phoneError = null;
                                        _isPhoneVerified = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 18),

// OTP Verification TextField (Visible after sending OTP)
                        if (_isOTPFieldVisible)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: 50, // Width of each OTP box
                                    height: 50, // Height of each OTP box
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 4), // Margin between boxes
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Color(0xFFE0E3E7), width: 2),
                                      color: Colors.white.withOpacity(
                                          0.5), // Reduced transparency
                                    ),
                                    child: TextField(
                                      controller: _otpPhoneControllers[index],
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        // Remove the hintText line
                                        hintStyle: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Color(0xFF57636C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 15), // Adjust as needed
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF101213),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      // maxLength: 1, // You can keep or remove this line
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          if (index < 5) {
                                            FocusScope.of(context).nextFocus();
                                          } else {
                                            FocusScope.of(context).unfocus();
                                          }
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: 10),

                              // Verify Phone OTP button
                              if (!_isPhoneVerified)
                                ElevatedButton(
                                  onPressed: _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                  ),
                                  child: Text(
                                    'Verify Phone OTP',
                                    style: TextStyle(color: Color(0xff015F3E)),
                                  ),
                                ),

                              // Phone verification status message
                              if (_phoneVerificationStatus != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text(
                                    _phoneVerificationStatus!,
                                    style: TextStyle(
                                      color: _isPhoneVerified
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: 15),

                        // Location Dropdown Field
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white
                                .withOpacity(0.7), // Background opacity
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE0E3E7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff015F3E),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            contentPadding: EdgeInsets.all(24),
                          ),
                          value: _selectedLocation,
                          hint: Text(
                            'Select Location',
                            style: TextStyle(
                              color: Color(0xFF57636C)
                                  .withOpacity(0.7), // Hint text opacity
                            ),
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLocation = newValue;
                            });
                          },
                          items: _locations
                              .map<DropdownMenuItem<String>>((String location) {
                            return DropdownMenuItem<String>(
                              value: location,
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: Color(0xFF101213).withOpacity(
                                      0.7), // Dropdown item text opacity
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 24),

                        // Sign Up Button (Submit form here)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff015F3E),
                                minimumSize: Size(150,
                                    50), // Set specific width (150) and height (50)
                                padding: EdgeInsets.symmetric(
                                    vertical: 16), // Optional: Custom padding
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ),

                            SizedBox(
                                height:
                                    20), // Adjust the space between the button and the text

                            GestureDetector(
                              onTap: () {
                                // Navigate to the login screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LoginScreen(), // Replace with your login screen widget
                                  ),
                                );
                              },
                              child: Text(
                                'Already have an account?Sign in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
