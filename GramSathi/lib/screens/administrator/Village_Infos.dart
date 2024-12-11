import 'package:flutter/material.dart';
import '/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Add_Village_screen.dart';
import 'Village_Details_Screen.dart';

class VillagePage extends StatefulWidget {
  @override
  _VillagePageState createState() => _VillagePageState();
}

class _VillagePageState extends State<VillagePage> {
  List<Map<String, dynamic>> _villages = [];
  // Cache to store fetched images
  Map<int, String?> _imageCache = {};

  // Function to fetch the villages and their corresponding president names
  Future<void> _fetchVillages() async {
    final response =
        await http.get(Uri.parse('${AppConfig.baseUrl}/admin-presidents'));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      setState(() {
        _villages = data.map((village) {
          return {
            'place_name': village['place_name'],
            'president_name': village['name'],
            'photo_id': int.tryParse(village['photoID'].toString()),
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load villages');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchVillages(); // Load villages when the page loads
  }

  // Function to navigate to the next screen with village details
  void _navigateToVillageDetails(String placeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VillageDetailsScreen(placeName: placeName),
      ),
    );
  }

  // Function to fetch the image URL from the /image/:id API
  Future<String?> _fetchProfileImage(int photoID) async {
    // Check if the image is already cached
    if (_imageCache.containsKey(photoID)) {
      return _imageCache[photoID]; // Return cached value if available
    }

    // If not cached, fetch the image URL from the server
    final imageUrl = '${AppConfig.baseUrl}/image/$photoID';

    // Store the fetched URL in the cache
    _imageCache[photoID] = imageUrl;

    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Villages')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to AddVillageScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddVillageScreen(),
                  ),
                ).then((shouldRefresh) {
                  // Default shouldRefresh to false if it is null
                  if (shouldRefresh == null || shouldRefresh) {
                    _fetchVillages(); // Refresh villages when returning or if no value was passed
                  }
                });
              },
              child: Text('Add a Village'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _villages.length,
                itemBuilder: (context, index) {
                  final village = _villages[index];
                  return FutureBuilder<String?>(
                    future: _fetchProfileImage(village['photo_id']!),
                    builder: (context, snapshot) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25, // Slightly increased the radius
                            backgroundColor: Colors
                                .grey[200], // Background color for CircleAvatar
                            backgroundImage: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? null
                                : snapshot.hasError || snapshot.data == null
                                    ? null // Show no image if there's an error or no data
                                    : NetworkImage(snapshot
                                        .data!), // Set image if data is available
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xff015F3E),
                                    size: 40,
                                  ) // Show icon while loading
                                : snapshot.hasError || snapshot.data == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Color(0xff015F3E),
                                        size: 40,
                                      ) // Show icon on error or null data
                                    : null, // No icon if image is available
                          ),
                          title: Text(village['place_name']),
                          subtitle: Text(village['president_name']),
                          onTap: () =>
                              _navigateToVillageDetails(village['place_name']),
                        ),
                      );
                    },
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
