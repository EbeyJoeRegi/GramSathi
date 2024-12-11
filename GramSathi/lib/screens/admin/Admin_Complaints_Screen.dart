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
  List<Map<String, dynamic>> _complaints = [];
  final TextEditingController _responseController = TextEditingController();
  String _selectedStatus = 'All'; // Filter by status (All, Pending, Resolved)

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}/admin/complaints?username=${widget.username}&status=$_selectedStatus',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _complaints =
              data.map((dynamic item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print('Failed to load complaints. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching complaints: $e');
    }
  }

  Future<void> _respondToComplaint(int id) async {
    final responseText = _responseController.text;

    try {
      final res = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/respondComplaint/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'response': responseText,
        }),
      );

      if (res.statusCode == 200) {
        _responseController.clear();
        setState(() {
          final index =
              _complaints.indexWhere((complaint) => complaint['id'] == id);
          if (index != -1) {
            _complaints[index]['response'] = responseText;
            _complaints[index]['status'] = 'Resolved'; // Mark as resolved
          }
        });
        Navigator.of(context).pop(); // Close dialog after update
      } else {
        print('Failed to respond to complaint. Status code: ${res.statusCode}');
      }
    } catch (e) {
      print('Error responding to complaint: $e');
    }
  }

  void _showResponseDialog(int complaintId, String currentResponse) {
    _responseController.text = currentResponse;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Respond to Complaint'),
          content: TextField(
            controller: _responseController,
            decoration: InputDecoration(
              labelText: 'Enter your response',
            ),
            maxLines: 4,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_responseController.text.isNotEmpty) {
                  _respondToComplaint(complaintId);
                }
              },
              child: Text('Submit Response'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Status Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              items: ['All', 'Pending', 'Resolved'].map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedStatus = newValue!;
                  _fetchComplaints(); // Refresh data based on the selected filter
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _complaints.length,
              itemBuilder: (context, index) {
                final complaint = _complaints[index];
                final adminResponse = complaint['response'] ?? '';
                final hasResponse = adminResponse.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    _showResponseDialog(complaint['id'], adminResponse);
                  },
                  child: Card(
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint['matter'] ?? 'No Matter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'By ${complaint['username'] ?? 'Unknown'} on ${DateFormat.yMMMd().format(DateTime.parse(complaint['time'] ?? DateTime.now().toIso8601String()))}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            hasResponse
                                ? 'Response: $adminResponse'
                                : 'Response Awaiting',
                            style: TextStyle(
                              color: hasResponse ? Colors.black : Colors.red,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Status: ${complaint['status'] ?? 'Pending'}',
                            style: TextStyle(
                              color: complaint['status'] == 'Resolved'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
