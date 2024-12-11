import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/users'));

    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    } else {
      // Handle the error
      print('Failed to load users');
    }
  }

  Future<void> _removeUser(int userId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/remove-user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
    } else {
      // Handle the error
      print('Failed to remove user');
    }
  }

  void _showUserDetailsDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
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
                  Text('User Details', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 16),
                  _buildDetailRow('Username', user['username']),
                  _buildDetailRow('Name', user['name']),
                  _buildDetailRow('Phone', user['phone']),
                  _buildDetailRow('Address', user['address']),
                  _buildDetailRow('Job Title', user['job_title']),
                  _buildDetailRow('Email', user['email']),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child:
                            Text('Close', style: TextStyle(color: Colors.red)),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        backgroundColor: Color(0xffE6F4E3),
      ),
      body: Container(
        color: Color(0xffE6F4E3), // Set the background color
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    color: Colors.white,
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 8, // Add some depth to the card
                    shadowColor: Color(0xff015F3E), // Set the shadow color
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        user['name'],
                        style: TextStyle(
                            fontWeight:
                                FontWeight.w500), // Make title a little bold
                      ),
                      subtitle: Text(
                        user['email'],
                        style: TextStyle(
                            fontWeight:
                                FontWeight.w300), // Make subtitle a little bold
                      ),
                      onTap: () => _showUserDetailsDialog(user),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeUser(user['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
