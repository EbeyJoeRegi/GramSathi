import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import '/config.dart';

class AdminManagementPage extends StatefulWidget {
  final String username;

  AdminManagementPage({required this.username});
  @override
  _AdminManagementPageState createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<dynamic> adminUsers = [];
  dynamic userDetails;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _raidController = TextEditingController();
  final TextEditingController _photoIDController = TextEditingController();
  late Uint8List _imageBytes = Uint8List(0);

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/user/${widget.username}'));

    if (response.statusCode == 200) {
      setState(() {
        userDetails = json.decode(response.body);
        _nameController.text = userDetails['name'];
        _phoneController.text = userDetails['phone'];
        _emailController.text = userDetails['email'];
        _raidController.text = userDetails['raID'];
        _jobTitleController.text = userDetails['job_title'];
        _photoIDController.text = userDetails['photoID'].toString();
      });

      // Fetch image from the server
      _fetchImage(userDetails['photoID'].toString());
    } else {
      // Handle the error
      print('Failed to load user details');
    }
  }

  Future<void> _fetchImage(String? photoID) async {
    if (photoID == null || photoID.isEmpty) return;

    final response =
        await http.get(Uri.parse('${AppConfig.baseUrl}/image/$photoID'));

    if (response.statusCode == 200) {
      setState(() {
        _imageBytes = response.bodyBytes;
      });
    } else {
      // Handle the error
      print('Failed to load image');
    }
  }

  Future<void> _fetchAdmins() async {
    final response = await http.get(Uri.parse(
        '${AppConfig.baseUrl}/admin-users?username=${widget.username}'));

    if (response.statusCode == 200) {
      setState(() {
        adminUsers = json.decode(response.body);
      });
    } else {
      // Handle the error
      print('Failed to load admin users');
    }
  }

  Future<void> _removeAdmin(int userId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/remove-admin'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      _fetchAdmins();
    } else {
      // Handle the error
      print('Failed to remove admin');
    }
  }

  Future<void> _addAdmin() async {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters long.')),
      );
      return;
    }

    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number must be 10 digits.')),
      );
      return;
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/add-admin'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'password': _passwordController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'job_title': _jobTitleController.text,
          'email': _emailController.text,
          'raID': _raidController.text,
          'admin_name': widget.username,
        }),
      );
      if (response.statusCode == 200) {
        _fetchAdmins();
        Navigator.pop(context);
        _clearForm();
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ration Card Number already exists.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add admin')),
        );
        print('Failed to add admin');
      }
    } catch (e) {
      print('Error adding admin: $e');
    }
  }

  Future<void> _uploadImageAndSave() async {
    // Upload new image
    final imageResponse = await http.post(
      Uri.parse('${AppConfig.baseUrl}/upload'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'image': base64Encode(_imageBytes),
      }),
    );

    if (imageResponse.statusCode == 200) {
      final imageData = json.decode(imageResponse.body);
      final newPhotoID = imageData['imageID'];

      // Save updated details with new photoID
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/update-user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': widget.username,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'raID': _raidController.text,
          'job_title': _jobTitleController.text,
          'photoID': newPhotoID,
        }),
      );

      if (response.statusCode == 200) {
        _fetchUserDetails(); // Reload the details
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Details updated successfully')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update user')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image')));
    }
  }

  void _clearForm() {
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _jobTitleController.clear();
    _emailController.clear();
    _raidController.clear();
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Admin', style: TextStyle(fontSize: 24)),
                  _buildTextField(_nameController, 'Name', Icons.badge),
                  _buildTextField(_passwordController, 'Password', Icons.lock,
                      obscureText: true),
                  _buildTextField(_phoneController, 'Phone', Icons.phone),
                  _buildTextField(_jobTitleController, 'Job Title', Icons.work),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  _buildTextField(
                      _raidController, 'Ration Card Number ', Icons.villa),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child:
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: _addAdmin,
                        child: Text('Add Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xff015F3E),
                          elevation: 8, // Add elevation to create a shadow
                          shadowColor: Color(
                              0xff015F3E), // Customize shadow color (optional)
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditUserDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit User Details', style: TextStyle(fontSize: 24)),
                  _buildTextField(_nameController, 'Name', Icons.badge),
                  _buildTextField(_phoneController, 'Phone', Icons.phone),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  _buildTextField(
                      _raidController, 'Ration Card Number', Icons.villa),
                  _buildTextField(_jobTitleController, 'Job Title', Icons.work),
                  // Image section
                  _imageBytes.isNotEmpty
                      ? Image.memory(_imageBytes, height: 150)
                      : Container(height: 150, color: Colors.grey),
                  ElevatedButton(
                    onPressed: () {
                      // Pick image logic here
                    },
                    child: Text('Change Image'),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child:
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: _uploadImageAndSave,
                        child: Text('Save Changes'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, IconData icon,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          cursorColor: Color(0xff015F3E), // Set cursor color
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: Color(0xff015F3E)),
            filled: true,
            fillColor: Colors.white, // Background color set to white
            prefixIcon: Icon(
              icon,
              color: Color(0xff015F3E), // Icon color
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: Color(0xff015F3E), // Default border color
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color:
                    Color(0xff015F3E).withOpacity(0.5), // Enabled border color
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color:
                    Color(0xff015F3E).withOpacity(0.3), // Focused border color
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12), // Space between boxes
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0, // Soft shadow blur
            offset: Offset(0, 2), // Slight shadow offset for depth
          ),
        ],
      ),
      width: double.infinity, // Ensure it takes the full width of the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label section
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xff015F3E), // Label text color
            ),
          ),
          // Value section
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black, // Value text color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Management'),
        backgroundColor: Color(0xffE6F4E3),
      ),
      body: Container(
        color: Color(0xffE6F4E3), // Set the background color
        child: Column(
          children: [
            // User details section
            userDetails != null
                ? Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Column containing user image and details
                        Column(
                          children: [
                            // User Image
                            CircleAvatar(
                              radius: 70, // Adjust the size of the image
                              backgroundImage: _imageBytes.isNotEmpty
                                  ? MemoryImage(_imageBytes)
                                  : null,
                              child: _imageBytes.isEmpty
                                  ? Icon(Icons.person, size: 80)
                                  : null,
                            ),
                            SizedBox(
                                height:
                                    20), // Space between image and details section

                            // User details section with separate boxes
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailBox('Name', userDetails['name']),
                                _buildDetailBox('Phone', userDetails['phone']),
                                _buildDetailBox('Email', userDetails['email']),
                                _buildDetailBox(
                                    'Ration Card ID', userDetails['raID']),
                                _buildDetailBox(
                                    'Job Title', userDetails['job_title']),
                              ],
                            ),
                          ],
                        ),

                        // Edit Button in the top-right corner
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed:
                                _showEditUserDetailsDialog, // or save logic here
                          ),
                        ),
                      ],
                    ),
                  )
                : CircularProgressIndicator(),

            //admin Details
            Expanded(
              child: ListView.builder(
                itemCount: adminUsers.length,
                itemBuilder: (context, index) {
                  final admin = adminUsers[index];
                  return Card(
                    color: Colors.white,
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    // Added shadow with the color 0xff015F3E
                    elevation: 8, // This adds some depth to the card
                    shadowColor: Color(0xff015F3E), // Set shadow color
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        admin['name'],
                        style: TextStyle(
                            fontWeight:
                                FontWeight.w500), // Make title a little bold
                      ),
                      subtitle: Text(
                        admin['email'],
                        style: TextStyle(
                            fontWeight:
                                FontWeight.w400), // Make subtitle a little bold
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeAdmin(admin['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdminDialog,
        child: Icon(Icons.add, color: Color(0xff001F14)),
        backgroundColor: Color(0xff55947E),
      ),
    );
  }
}
