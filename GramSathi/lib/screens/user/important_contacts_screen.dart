import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For making phone calls
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class ImportantContactsScreen extends StatefulWidget {
  const ImportantContactsScreen({super.key});

  @override
  _ImportantContactsScreenState createState() =>
      _ImportantContactsScreenState();
}

class _ImportantContactsScreenState extends State<ImportantContactsScreen> {
  List<Map<String, dynamic>> adminContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminContacts();
  }

  Future<void> _fetchAdminContacts() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/admins'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          adminContacts =
              data.map((dynamic item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print(
            'Failed to load admin contacts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching admin contacts: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Important Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        leading: Padding(
          padding:
              const EdgeInsets.only(left: 9.0), // Adjust this padding as needed
          child: Image.asset(
            'assets/images/icon.png',
            height: 56.0,
            width: 54.0,
          ),
        ),
        leadingWidth:
            60, // Adjust this to make the icon's space narrower, bringing it closer to the title
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: ListView(
          children: [
            // Admin Contacts
            if (adminContacts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Admin Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...adminContacts.map((admin) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 80, // Increase the height as needed
                    child: Center(
                      child: ListTile(
                        leading: const Icon(Icons.person,
                            color: Color(0xff015F3E), size: 40), // Random icon
                        title: Text(admin['name']),
                        subtitle: Text(admin['job_title'] ?? 'No Job Title'),
                        onTap: () => _makePhoneCall(admin['phone']),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
