import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config.dart';

class MarketUpdatesScreen extends StatefulWidget {
  const MarketUpdatesScreen({super.key});

  @override
  _MarketUpdatesScreenState createState() => _MarketUpdatesScreenState();
}

class _MarketUpdatesScreenState extends State<MarketUpdatesScreen> {
  List<dynamic> locations = [];
  List<dynamic> crops = [];
  String? selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final response =
        await http.get(Uri.parse('${AppConfig.baseUrl}/locations'));
    if (response.statusCode == 200) {
      setState(() {
        locations = json.decode(response.body);
      });
    } else {
      // Handle errors
      throw Exception('Failed to load locations');
    }
  }

  Future<void> _fetchCrops(String placeId) async {
    final response =
        await http.get(Uri.parse('${AppConfig.baseUrl}/crops/$placeId'));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        crops = json.decode(response.body);
      });
    } else if (response.statusCode == 404) {
      setState(() {
        crops = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No crops found for this placeId')),
      );
    } else {
      throw Exception('Failed to load crops');
    }
  }

  void _onLocationChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedLocation = value;
        _fetchCrops(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Updates'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/user.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent Overlay
          Container(
            color: const Color.fromARGB(255, 255, 254, 254)
                .withOpacity(0.5), // Adjust opacity here
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        width: 2.0),
                    color: Colors.white.withOpacity(0.7),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text('Select Location'),
                    value: selectedLocation,
                    onChanged: _onLocationChanged,
                    underline: const SizedBox(), // Hides the default underline
                    isExpanded: true,
                    items: locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location['id'].toString(),
                        child: Text(
                          location['place_name'],
                          style: const TextStyle(color: Colors.teal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedLocation != null) ...[
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: crops.length,
                      itemBuilder: (context, index) {
                        final crop = crops[index];
                        final cropName = crop['crop_name'];
                        final cropPrice = crop['price'];
                        final avgPriceRaw = crop['avg_price'];

                        // Extract avg_price value from Decimal128 representation
                        final avgPrice = avgPriceRaw is Map
                            ? double.tryParse(avgPriceRaw['\$numberDecimal']) ??
                                0.0
                            : double.tryParse(avgPriceRaw.toString()) ?? 0.0;

                        return Opacity(
                          opacity: 0.8, // Adjust opacity here
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 4.0,
                            child: ListTile(
                              subtitle: Text(
                                'Crop: $cropName\nPrice: $cropPrice (${crop['month_year']})\nAverage Price: ${avgPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
