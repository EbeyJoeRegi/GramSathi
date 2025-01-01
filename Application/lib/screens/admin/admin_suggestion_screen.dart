import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class AdminSuggestionsScreen extends StatefulWidget {
  final String username;
  AdminSuggestionsScreen({required this.username});

  @override
  _AdminSuggestionsScreenState createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> {
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
        print('Failed to load suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> _postResponse(
      Map<String, dynamic> suggestion, String responseText) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/respondSuggestion'), // Replace with your API URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': suggestion['id'],
          'response': responseText,
        }),
      );

      if (response.statusCode == 200) {
        _fetchSuggestions(); // Refresh the suggestions after posting a response
      } else {
        print('Failed to post response');
      }
    } catch (e) {
      print('Error posting response: $e');
    }
  }

  void _showResponseDialog(Map<String, dynamic> suggestion) {
    final TextEditingController _responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Respond to Suggestion'),
          contentPadding:
              EdgeInsets.all(12.0), // Adjust this padding to reduce the gap
          content: Column(
            mainAxisSize: MainAxisSize
                .min, // Ensures the dialog doesn't take up extra space
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns the TextField to the left
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey, width: 1.5), // Border to create a box
                  borderRadius:
                      BorderRadius.circular(8.0), // Rounded corners for the box
                ),
                padding: EdgeInsets.all(8.0), // Padding inside the box
                child: Center(
                  child: TextField(
                    controller: _responseController,
                    decoration: InputDecoration(
                      labelText: 'Response',

                      border: InputBorder
                          .none, // Removes the default border around the TextField
                    ),
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Ensures buttons are aligned
              children: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Submit'),
                  onPressed: () {
                    final responseText = _responseController.text;
                    if (responseText.isNotEmpty) {
                      _postResponse(suggestion, responseText);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFF015F3E), // Border color
                  width: 2.0,
                ),
                borderRadius:
                    BorderRadius.circular(8.0), // Optional: Add rounded corners
              ),
              margin: EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: Color(0xFFE6F4E3),
                margin: EdgeInsets.zero,
                //Ensure Card background is transparent to show container color
                child: ListTile(
                  title: Text(
                    suggestion['title'] ?? 'No Title',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By ${suggestion['username'] ?? 'Unknown'} on ${DateFormat.yMMMd().format(DateTime.parse(suggestion['created_at'] ?? DateTime.now().toIso8601String()))}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        suggestion['content'] ?? 'No Content',
                        textAlign: TextAlign.justify, // Justify the text
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        suggestion['response'] == null ||
                                suggestion['response'].isEmpty
                            ? 'Waiting for admin response'
                            : 'Admin : ${suggestion['response']}',
                        textAlign: TextAlign.justify, // Justify the text
                        style: TextStyle(
                          color: suggestion['response'] == null ||
                                  suggestion['response'].isEmpty
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showResponseDialog(suggestion),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
