import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '/config.dart';

class UserProfilePage extends StatefulWidget {
  final String username;

  UserProfilePage({required this.username});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  String _errorMessage = '';
  ImageProvider? _profileImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> updateProfilePicture(String username, int newImageID) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/user/profile/photo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'newImageID': newImageID,
        }),
      );

      if (response.statusCode == 200) {
        print('Profile picture updated successfully');
      } else {
        print('Failed to update profile picture: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/user/profile?username=${widget.username}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _jobTitleController.text = data['job_title'] ?? '';
          _emailController.text = data['email'] ?? '';
        });

        if (data['photoID'] != null) {
          await _fetchUserProfileImage(data['photoID']);
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'User not found. Please check the username.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching user data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //fetching from DB
  Future<void> _fetchUserProfileImage(int photoID) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/image/$photoID'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _profileImage = MemoryImage(response.bodyBytes);
        });
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  //fetching from Cloudinary url
  // Future<void> _fetchUserProfileImage(int photoID) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('${AppConfig.baseUrl}/cloud_image/$photoID'),
  //     );

  //     if (response.statusCode == 200) {
  //       if (response.headers['content-type']?.startsWith('application/json') ??
  //           false) {
  //         final data = jsonDecode(response.body);
  //         final imageUrl =
  //             data['url']; // Assuming the 'url' is part of the response

  //         // Fetch the image from the URL in case of the second API format
  //         final imageResponse = await http.get(Uri.parse(imageUrl));
  //         if (imageResponse.statusCode == 200) {
  //           setState(() {
  //             _profileImage = MemoryImage(
  //                 imageResponse.bodyBytes); // Use image bytes from URL
  //           });
  //         } else {
  //           print('Failed to fetch image from URL');
  //         }
  //       }
  //     } else {
  //       print('Failed to fetch image: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching profile image: $e');
  //   }
  // }

  Future<void> _updateUserData() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/user/profile/update'
          '?username=${Uri.encodeComponent(widget.username)}'
          '&name=${Uri.encodeComponent(_nameController.text)}'
          '&jobTitle=${Uri.encodeComponent(_jobTitleController.text)}');

      final response = await http.put(uri);

      if (response.statusCode == 200) {
        await _fetchUserData();
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      try {
        //Upload the image to DB
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.baseUrl}/upload'),
        );

        //Upload the image to Cloudinary
        // final request = http.MultipartRequest(
        //   'POST',
        //   Uri.parse('${AppConfig.baseUrl}/cloud_upload'),
        // );

        request.files.add(
          await http.MultipartFile.fromPath(
              'image', file.path), // Ensure the field name matches the backend
        );

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final responseData = json.decode(responseBody);
          final newImageID = responseData['imageId'];

          // Step 2: Call the updateProfilePicture function
          await updateProfilePicture(widget.username, newImageID);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated successfully')),
          );

          // Step 3: Refresh user data to reflect the changes
          await _fetchUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile picture')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during upload: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 53.0,
                width: 52.0,
              ),
            ),
            Text(
              'Profile',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        leading: null, // Removes the back arrow button
        automaticallyImplyLeading: false, // Ensures no back button is added
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit,
                color: Color(0xff015F3E)),
            onPressed: () {
              if (_isEditing) {
                _updateUserData();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.home, color: Color(0xff015F3E)),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user_home',
                ModalRoute.withName('/'),
                arguments: {
                  'username': widget.username,
                  'name': _nameController.text,
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 75,
                              backgroundImage: _profileImage ??
                                  AssetImage('assets/images/user.jpg'),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: Color(0xff015F3E),
                                size: 30,
                              ),
                              onPressed: _pickAndUploadImage,
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        _buildTextField(
                            'Name', _nameController, Color(0xff015F3E), true),
                        _buildTextField('Phone Number', _phoneController,
                            Color(0xff015F3E), false),
                        _buildTextField('Address', _addressController,
                            Color(0xff015F3E), false),
                        _buildTextField('Job Title', _jobTitleController,
                            Color(0xff015F3E), true),
                        _buildTextField('Email', _emailController,
                            Color(0xff015F3E), false),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      Color color, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          border: OutlineInputBorder(),
        ),
        enabled: isEditable ? _isEditing : false,
        style: TextStyle(color: color),
      ),
    );
  }
}
