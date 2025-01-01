import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';

class VillageAnnouncementPage extends StatefulWidget {
  final String username;
  VillageAnnouncementPage({required this.username});

  @override
  _VillageAnnouncementPageState createState() =>
      _VillageAnnouncementPageState();
}

class _VillageAnnouncementPageState extends State<VillageAnnouncementPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _message = '';
  List<Map<String, dynamic>> _announcements = [];
  int? _currentAnnouncementId; // Track the current announcement being updated
  String name = '';
  String place = '';

  @override
  void initState() {
    super.initState();
    fetchUserName(widget.username);
  }

  Future<void> fetchUserName(String username) async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/user/$username'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'];
          place = data['address'];
        });
        _fetchAnnouncements(place);
      } else if (response.statusCode == 404) {
        print('User not found');
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  Future<void> _fetchAnnouncements(String place) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/announcements?place=$place'), // Replace with your IP address
      );

      if (response.statusCode == 200) {
        setState(() {
          _announcements =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        setState(() {
          _message = 'Failed to load announcements';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final title = _titleController.text;
    final content = _contentController.text;

    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/createAnnouncement'), // Replace with your IP address
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'admin': name,
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Announcement created successfully';
          _fetchAnnouncements(place); // Refresh the announcements list
          _titleController.clear();
          _contentController.clear();
        });
      } else {
        setState(() {
          _message = 'Failed to create announcement';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${AppConfig.baseUrl}/deleteAnnouncement/$id'), // Replace with your IP address
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Announcement deleted successfully';
          _fetchAnnouncements(place); // Refresh the announcements list
        });
      } else {
        setState(() {
          _message = 'Failed to delete announcement';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  Future<void> _updateAnnouncement(int id, String title, String content) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${AppConfig.baseUrl}/updateAnnouncement/$id'), // Replace with your IP address
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'admin': name,
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Announcement updated successfully';
          _fetchAnnouncements(place); // Refresh the announcements list
          _currentAnnouncementId =
              null; // Clear the current announcement being updated
          _titleController.clear();
          _contentController.clear();
        });
      } else {
        setState(() {
          _message = 'Failed to update announcement';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  void _showUpdateDialog(int id, String currentTitle, String currentContent) {
    _titleController.text = currentTitle;
    _contentController.text = currentContent;
    _currentAnnouncementId = id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _currentAnnouncementId =
                  null; // Clear the current announcement being updated
              // Clear the text fields when cancel is pressed
              _titleController.clear();
              _contentController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentAnnouncementId != null) {
                _updateAnnouncement(_currentAnnouncementId!,
                    _titleController.text, _contentController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('dd-MM-yy');
      return formatter.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Aligning to the left
          children: [
            Text(
              'Announcements',
              style: TextStyle(
                fontWeight: FontWeight.w500, // Makes the text bold
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white, // Set AppBar color
        elevation: 0, // Remove shadow
      ),

      body: Container(
        color: Colors.white, // Set background color to white
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Announcements list
            Expanded(
              child: ListView.builder(
                itemCount: _announcements.length,
                shrinkWrap: true, // Ensure it takes up only the space it needs
                physics: const BouncingScrollPhysics(), // Enable bounce effect
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6F4E3),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Color(0xff015F3E)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        announcement['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // Makes the title bold
                          color: Color(
                              0xFF015F3E), // Sets the title color to #015F3E
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(announcement['content'],
                              textAlign: TextAlign.justify),
                          const SizedBox(height: 4),
                          Text('Posted By: ${announcement['admin']}',
                              textAlign: TextAlign.justify),
                          const SizedBox(height: 4),
                          Text(
                            'Created at: ${_formatDate(announcement['created_at'])}', // Only date
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteAnnouncement(announcement['id']),
                      ),
                      onTap: () => _showUpdateDialog(
                        announcement['id'],
                        announcement['title'],
                        announcement['content'],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            // New announcement section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.9), // Grey shadow
                    blurRadius: 5.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      color: Color(0xFF015F3E), // Set the text color to #C4EDB2
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      color: Color(0xFF015F3E), // Set the text color to #C4EDB2
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 100.0,
                    height:
                        50, // Set the desired width for the button (adjust as needed)
                    child: ElevatedButton(
                      onPressed: _createAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Color(0xFF015F3E), // Button color to #015F3E
                      ),
                      child: Text(
                        'Create Announcement',
                        style: TextStyle(
                          color: Colors.white, // Text color to white
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                    ),
                  ),
                  if (_message.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _message,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
