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

  // Function to get background image based on crop name
  String _getBackgroundImage(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'carrot':
        return 'assets/vegetables/carrot.jpg';
      case 'arecanut':
        return 'assets/vegetables/arecaunut.jpg'; // Local image for carrot
      // Add more cases for different crops as necessary
      case 'onion':
        return 'assets/vegetables/onion.jpg';
      case 'tomato':
        return 'assets/vegetables/tomato.jpg';
      case 'pumpkin':
        return 'assets/vegetables/pumpkin.jpg';
      case 'pepper':
        return 'assets/vegetables/pepper.jpg';
      case 'lemon':
        return 'assets/vegetables/lemon.jpg';
      default:
        return 'assets/vegetables/default1.jpg'; // Default image if crop not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Changed to white color
          ),
          child: AppBar(
            titleSpacing: 0,
            backgroundColor:
                Colors.transparent, // Make AppBar background transparent
            elevation: 0,
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 9.0),
                  child: Image.asset(
                    'assets/images/icon.png',
                    height: 53.0,
                    width: 52.0,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Market Updates',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xfff0f0f0), // Light gray for the background
              Colors.white, // White for the foreground
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom container with border and rounded corners
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Color(0xff005F3D).withOpacity(0.5), // Soft border
                    width: 1.5,
                  ),
                  color:
                      Colors.white.withOpacity(0.9), // Semi-transparent white
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      offset: Offset(0, 4), // Soft shadow
                    ),
                  ],
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
                        style: const TextStyle(color: Color(0xff015F3E)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (selectedLocation != null) ...[
                const SizedBox(height: 20),
                if (crops.isEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/no_data.png', // Placeholder image for no data
                          height: 150,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No crops found for this location. Please try another.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xff005F3D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
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
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  image: AssetImage(_getBackgroundImage(
                                      cropName)), // Set background image
                                  fit:
                                      BoxFit.cover, // Cover the whole container
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.6),
                                    BlendMode.darken,
                                  ), // Adding black opacity filter
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8.0,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cropName,
                                      style: const TextStyle(
                                        fontSize: 20.0, // Increased font size
                                        fontWeight:
                                            FontWeight.bold, // Bold text
                                        color: Colors
                                            .white, // White color for cropName
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            8), // Space between cropName and other text
                                    Text(
                                      'Price: $cropPrice (${crop['month_year']})',
                                      style: const TextStyle(
                                        fontSize: 16.0, // Default font size
                                        color: Colors
                                            .white, // White color for price and avg price
                                      ),
                                    ),
                                    Text(
                                      'Average Price: ${avgPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16.0, // Default font size
                                        color: Colors
                                            .white, // White color for average price
                                      ),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }
}
