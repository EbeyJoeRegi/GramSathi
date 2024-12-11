import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';

class AdminComplaintScreen extends StatefulWidget {
  final String username;

  AdminComplaintScreen({required this.username});

  @override
  _AdminComplaintScreenState createState() => _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  List<Map<String, dynamic>> _queries = [];
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQueries();
  }

  Future<void> _fetchQueries() async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.baseUrl}/admin/queries?username=${widget.username}&type=2'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _queries =
              data.map((dynamic item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print('Failed to load queries. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching queries: $e');
    }
  }

  Future<void> _respondToQuery(int id) async {
    final responseText = _responseController.text;

    try {
      final res = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/respondQuery/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'response': responseText,
        }),
      );

      if (res.statusCode == 200) {
        setState(() {
          _responseController.clear();
          final index = _queries.indexWhere((query) => query['id'] == id);
          if (index != -1) {
            _queries[index]['admin_response'] = responseText; // Update response
          }
        });
        Navigator.of(context).pop(); // Close the dialog after successful update
      } else {
        print('Failed to respond to query. Status code: ${res.statusCode}');
      }
    } catch (e) {
      print('Error responding to query: $e');
    }
  }

  void _showResponseDialog(int queryId, String currentResponse) {
    _responseController.text = currentResponse;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Respond to Complaint',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            child: TextField(
              controller: _responseController,
              decoration: InputDecoration(
                labelText: 'Enter your response',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_responseController.text.isNotEmpty) {
                  _respondToQuery(queryId);
                }
              },
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Color(0xFF015F3E), // Green color for Submit button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red, // Red color for Cancel button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _queries.length,
          itemBuilder: (context, index) {
            final query = _queries[index];
            final adminResponse =
                query['admin_response']; // Access admin_response directly
            final hasResponse = adminResponse != null &&
                adminResponse.isNotEmpty; // Check for valid response

            return GestureDetector(
              onTap: () {
                _showResponseDialog(query['id'], adminResponse ?? '');
              },
              child: Card(
                color: Color(0xFFE6F4E3), // Set the card color
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Color(0xFF015F3E), // Set the border color
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query['matter'] ?? 'No Matter',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'By ${query['username'] ?? 'Unknown'} on ${DateFormat.yMMMd().format(DateTime.parse(query['time'] ?? DateTime.now().toIso8601String()))}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        hasResponse
                            ? 'Admin: $adminResponse'
                            : 'Response Awaiting', // Display appropriate message
                        style: TextStyle(
                          color: hasResponse ? Colors.black : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
