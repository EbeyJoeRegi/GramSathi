import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart'; // Assuming AppConfig is defined here for baseUrl

class TalukAnnouncementsScreen extends StatefulWidget {
  @override
  _TalukAnnouncementsScreenState createState() =>
      _TalukAnnouncementsScreenState();
}

class _TalukAnnouncementsScreenState extends State<TalukAnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/announcement-administrator'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _announcements =
              data.map((dynamic item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print(
            'Failed to load announcements. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taluk Announcements'),
        backgroundColor: Color(0xFF015F3E), // Green color for AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _announcements.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  final createdAt = DateTime.parse(announcement['created_at']);
                  final formattedDate =
                      DateFormat.yMMMd().add_jm().format(createdAt);

                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Color(0xFF015F3E), // Border color
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
                            announcement['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF015F3E), // Title color
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            announcement['content'] ?? 'No Content',
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Posted by: ${announcement['admin'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            'Posted on: $formattedDate',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
