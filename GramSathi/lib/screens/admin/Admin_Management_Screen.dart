import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import '/config.dart';
import 'package:image_picker/image_picker.dart';

class AdminManagementPage extends StatefulWidget {
  final String username;

  AdminManagementPage({required this.username});
  @override
  _AdminManagementPageState createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<dynamic> adminUsers = [];
  bool isEditable = false; // Track whether the fields are editable
  dynamic userDetails;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _raidController = TextEditingController();
  late TextEditingController _adminNameController = TextEditingController();
  late TextEditingController _adminPhoneController = TextEditingController();
  late TextEditingController _adminjobTitleController = TextEditingController();
  late TextEditingController _adminEmailController = TextEditingController();
  late TextEditingController _adminRaidController = TextEditingController();
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
        _adminNameController.text = userDetails['name'];
        _adminPhoneController.text = userDetails['phone'];
        _adminEmailController.text = userDetails['email'];
        _adminRaidController.text = userDetails['raID'];
        _adminjobTitleController.text = userDetails['job_title'];
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = imageBytes; // Update the image preview
      });
      await _uploadImage(pickedFile);
    }
  }

  Future<void> _uploadImage(XFile file) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}/upload'));
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respData = await response.stream.bytesToString();
        final jsonData = json.decode(respData);
        final imageId = jsonData['imageId'].toString();

        // Update user profile photo
        await _updateUserProfilePhoto(imageId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed! Try again.')));
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _updateUserProfilePhoto(String imageId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/user/profile/photo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': widget.username,
          'newImageID': imageId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile picture.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture.')));
    }
  }

  void _saveUserDetails() async {
    Map<String, dynamic> updatedDetails = {
      'id': userDetails['id'],
      'name': _adminNameController.text,
      'phone': _adminPhoneController.text,
      'email': _adminEmailController.text,
      'raID': _adminRaidController.text,
      'job_title': _adminjobTitleController.text,
    };
    try {
      final url = '${AppConfig.baseUrl}/update-user';

      // Send the POST request to the backend
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedDetails),
      );

      if (response.statusCode == 200) {
        print('User details updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User details updated successfully!')),
        );
      } else {
        print('Failed to update user details.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update user details. Please try again.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
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

  Widget _buildEditableField(
      String label, TextEditingController controller, bool isEditable) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xff015F3E),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xff015F3E), width: 2.0),
          ),
        ),
        style: TextStyle(fontSize: 15, color: Colors.black),
        readOnly:
            !isEditable, // Make fields editable only when isEditable is true
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
                            // User Image with edit icon overlay
                            GestureDetector(
                              onTap: _pickImage, // Trigger image selection
                              child: CircleAvatar(
                                radius: 70,
                                backgroundImage: _imageBytes.isNotEmpty
                                    ? MemoryImage(_imageBytes)
                                    : null,
                                child: _imageBytes.isEmpty
                                    ? Icon(Icons.person, size: 80)
                                    : null,
                              ),
                            ),
                            SizedBox(
                                height:
                                    5), // Space between image and details section

                            // User details section with editable text fields
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEditableField(
                                    'Name', _adminNameController, isEditable),
                                _buildEditableField(
                                    'Phone', _adminPhoneController, isEditable),
                                _buildEditableField(
                                    'Email', _adminEmailController, isEditable),
                                _buildEditableField('Ration Card ID',
                                    _adminRaidController, isEditable),
                                _buildEditableField('Job Title',
                                    _adminjobTitleController, isEditable),
                              ],
                            ),
                          ],
                        ),

                        // Save Button in the top-right corner
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: Icon(isEditable ? Icons.save : Icons.edit),
                            onPressed: () {
                              setState(() {
                                if (isEditable) {
                                  _saveUserDetails(); // Call your save method here
                                }
                                isEditable = !isEditable; // Toggle editability
                              });
                            },
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
