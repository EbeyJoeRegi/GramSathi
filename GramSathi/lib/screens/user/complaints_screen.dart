import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';

class ComplaintsScreen extends StatefulWidget {
  final String username;

  ComplaintsScreen({required this.username});

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final TextEditingController _complaintController = TextEditingController();
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/queries?username=${widget.username}&type=2'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> complaintsJson = json.decode(response.body);
        setState(() {
          _complaints =
              complaintsJson.map((c) => Map<String, dynamic>.from(c)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load complaints';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _createComplaint() async {
    final matter = _complaintController.text;
    if (matter.isEmpty) {
      return;
    }

    final newComplaint = {
      'username': widget.username,
      'matter': matter,
      'time': DateTime.now().toIso8601String(),
      'type': '2',
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/createQuery'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newComplaint),
      );

      if (response.statusCode == 200) {
        setState(() {
          _complaints.insert(0, newComplaint);
          _complaintController.clear();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to create complaint';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  DateTime convertUtcToIst(DateTime utcDateTime) {
    return utcDateTime.add(Duration(hours: 5, minutes: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6F4E3),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          final dateTimeUtc = DateTime.parse(complaint['time']);
                          final dateTimeIst = convertUtcToIst(dateTimeUtc);

                          final formattedDate =
                              DateFormat('dd-MM-yy').format(dateTimeIst);
                          final formattedTime =
                              DateFormat('hh:mm a').format(dateTimeIst);

                          return Container(
                            margin: EdgeInsets.all(8.0),
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 6.0,
                                  spreadRadius: 1.0,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(
                                complaint['admin_response'] != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: complaint['admin_response'] != null
                                    ? Colors.green
                                    : Colors.green,
                              ),
                              title: Text(
                                complaint['matter'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$formattedDate • $formattedTime',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: complaint['admin_response'] != null
                                        ? 1.0
                                        : 0.5,
                                    duration: Duration(seconds: 1),
                                    child: Text(
                                      complaint['admin_response'] ??
                                          'Awaiting response',
                                      style: TextStyle(
                                        color:
                                            complaint['admin_response'] != null
                                                ? Colors.black
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showComplaintDialog(complaint);
                              },
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF015F3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF015F3E).withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _complaintController,
                      decoration: InputDecoration(
                        hintText: 'Enter your enquiry',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _createComplaint,
                    backgroundColor: Color(0xff015F3E),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
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

  void _showComplaintDialog(Map<String, dynamic> complaint) {
    final dateTimeUtc = DateTime.parse(complaint['time']);
    final dateTimeIst = convertUtcToIst(dateTimeUtc);

    final formattedDate = DateFormat('dd-MM-yy').format(dateTimeIst);
    final formattedTime = DateFormat('hh:mm a').format(dateTimeIst);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                complaint['matter'],
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              Text(
                complaint['admin_response'] ?? 'Awaiting response',
                style: TextStyle(
                  color: complaint['admin_response'] != null
                      ? Colors.black
                      : Colors.red,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '$formattedDate • $formattedTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
