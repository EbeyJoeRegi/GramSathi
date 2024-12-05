import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class SuggestionsScreen extends StatefulWidget {
  final String username;

  SuggestionsScreen({required this.username});

  @override
  _SuggestionsScreenState createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/suggestions?username=${widget.username}'), // Replace with your API URL
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions =
              data.map((dynamic item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print(
            'Failed to load suggestions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> _postSuggestion() async {
    final title = _titleController.text;
    final content = _contentController.text;

    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/createSuggestion'), // Replace with your API URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'username': widget.username,
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        _titleController.clear();
        _contentController.clear();
        _fetchSuggestions();
      } else {
        print('Failed to post suggestion. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting suggestion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6F4E3), // Light green background
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Color(0xff005F3D).withOpacity(
                            0.5), // Lighter and more spread out border
                        width: 2.0, // Increased width for a more spread look
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff005F3D).withOpacity(
                              0.2), // Subtle shadow of the same border color
                          spreadRadius: 1, // Increased spread
                          blurRadius: 3, // Soft blur effect for the shadow
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              suggestion['title'] ?? 'No Title',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff005F3D),
                              ),
                            ),
                            Icon(Icons.more_vert, color: Colors.green[600]),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'By ${suggestion['username'] ?? 'Unknown'} on ${DateFormat.yMMMd().format(DateTime.parse(suggestion['created_at'] ?? DateTime.now().toIso8601String()))}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          suggestion['content'] ?? 'No Content',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          suggestion['response'] == null ||
                                  suggestion['response'].isEmpty
                              ? 'Waiting for Admin response'
                              : 'Admin : ${suggestion['response']}',
                          style: TextStyle(
                            color: suggestion['response'] == null ||
                                    suggestion['response'].isEmpty
                                ? Colors.red
                                : Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(
                    0xffF7F7F7), // Soft light gray background for more separation
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(
                        0.8), // Slightly darker shadow for better separation
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 6), // More pronounced shadow effect
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(
                  vertical: 16.0), // Adds space around the form
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title TextField
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Color(0xff005F3D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0), // Increased space to prevent cramping

                  // Content TextField
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: TextStyle(color: Color(0xff005F3D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(
                      height:
                          20.0), // Added extra space to separate the button further

                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _postSuggestion,
                      child: Text('Post Suggestion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.lerp(Color(0xff015F3E),
                            Colors.white, 0.1), // 30% blend with white

// Button background color
                        foregroundColor: Colors.white, // Button text color
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
