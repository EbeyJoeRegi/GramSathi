import 'dart:convert';
import 'package:flutter/material.dart';
import '/config.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VillageDetailsScreen extends StatefulWidget {
  final String placeName;

  const VillageDetailsScreen({Key? key, required this.placeName})
      : super(key: key);

  @override
  _VillageDetailsScreenState createState() => _VillageDetailsScreenState();
}

void _makeCall(String phoneNumber) async {
  final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(callUri)) {
    await launchUrl(callUri);
  } else {
    throw 'Could not launch $phoneNumber';
  }
}

void _sendEmail(String emailAddress) async {
  final Uri emailUri = Uri(scheme: 'mailto', path: emailAddress);
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw 'Could not launch email client';
  }
}

class _VillageDetailsScreenState extends State<VillageDetailsScreen> {
  int residentCount = 0;
  List<Map<String, dynamic>> admins = [];

  // Fetch number of residents for the selected village
  Future<void> _fetchResidentCount() async {
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/count-users/${widget.placeName}'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        residentCount = data['userCount'];
      });
    } else if (response.statusCode == 404) {
      residentCount = 0;
    } else {
      throw Exception('Failed to load resident count');
    }
  }

  // Fetch admins for the selected village
  Future<void> _fetchAdmins() async {
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/all-admins/${widget.placeName}'));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      setState(() {
        admins = data.map((admin) {
          return {
            'name': admin['name'],
            'phone': admin['phone'],
            'job_title': admin['job_title'],
            'email': admin['email'],
            'photo_id': int.tryParse(admin['photoID'].toString()),
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load admins');
    }
  }

  // Fetch profile image using photoID
  Future<Image?> _fetchProfileImage(int photoID) async {
    final response =
        await http.get(Uri.parse('${AppConfig.baseUrl}/image/$photoID'));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    return null; // Return null if image fetch fails
  }

  @override
  void initState() {
    super.initState();
    _fetchResidentCount(); // Load resident count
    _fetchAdmins(); // Load admin details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.placeName} Details')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            // Display number of residents
            Text('Number of Residents: $residentCount',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Admins',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            // List of admins
            ListView.builder(
              shrinkWrap: true,
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                return FutureBuilder<Image?>(
                  future: _fetchProfileImage(admin['photo_id']),
                  builder: (context, snapshot) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading:
                            snapshot.connectionState == ConnectionState.waiting
                                ? const Icon(Icons.person,
                                    color: Color(0xff015F3E),
                                    size: 40) // Loading icon
                                : snapshot.hasError || snapshot.data == null
                                    ? const Icon(Icons.person,
                                        color: Color(0xff015F3E),
                                        size: 40) // Error fallback icon
                                    : CircleAvatar(
                                        backgroundImage: snapshot.data!.image,
                                      ),
                        title: Text(admin['name']),
                        subtitle: Text(admin['job_title']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.phone),
                              onPressed: () {
                                _makeCall(admin['phone']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.email),
                              onPressed: () {
                                _sendEmail(admin['email']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
