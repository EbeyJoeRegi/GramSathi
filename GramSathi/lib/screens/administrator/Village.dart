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
  Map<int, String?> _imageCache = {};

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
    _fetchVillages();
  }

  void _navigateToVillageDetails(String placeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VillageDetailsScreen(placeName: placeName),
      ),
    );
  }

  Future<String?> _fetchProfileImage(int photoID) async {
    if (_imageCache.containsKey(photoID)) {
      return _imageCache[photoID];
    }
    final imageUrl = '${AppConfig.baseUrl}/image/$photoID';
    _imageCache[photoID] = imageUrl;
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   //title: Text('Villages'),
      //   backgroundColor: Colors.white,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            radius: 25,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? null
                                : snapshot.hasError || snapshot.data == null
                                    ? null
                                    : NetworkImage(snapshot.data!),
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xff015F3E),
                                    size: 40,
                                  )
                                : snapshot.hasError || snapshot.data == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Color(0xff015F3E),
                                        size: 40,
                                      )
                                    : null,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVillageScreen(),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh) {
              _fetchVillages();
            }
          });
        },
        backgroundColor: Color(0xFF55947E), // Button background color
        icon: Icon(
          Icons.add, // Icon for the button
          color: Color(0xFF001F14), // Icon color
        ),
        label: Text(
          'Add Village', // Text label for the button
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF001F14), // Text color
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
