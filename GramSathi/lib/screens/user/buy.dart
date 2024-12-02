import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/config.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Add the cropImageMap here
Map<String, String> cropImageMap = {
  'arecanut': 'assets/vegetables/arecaunut.jpg',
  'capsicum': 'assets/vegetables/capsicum.jpg',
  'carrot': 'assets/vegetables/carrot.jpg',
  'chilli': 'assets/vegetables/chilli.jpg',
  'corriander': 'assets/vegetables/coriander.jpg',
  'corn': 'assets/vegetables/corn.jpg',
  'curry': 'assets/vegetables/curry.jpg',
  'cucumber': 'assets/vegetables/cucumber.jpg',
  'lemon': 'assets/vegetables/lemon.jpg',
  'onion': 'assets/vegetables/onion.jpg',
  'pumpkin': 'assets/vegetables/pumpkin.jpg',
  'pepper': 'assets/vegetables/pepper.jpg',
  'rice': 'assets/vegetables/rice.jpg',
  'tomato': 'assets/vegetables/tomato.jpg',
  'wheat': 'assets/vegetables/wheat.jpg',
};

class BuyScreen extends StatefulWidget {
  final String username;
  BuyScreen({required this.username});
  @override
  _BuyScreenState createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  String dropdownValue = 'My Village';
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCrops();
  }

  Future<void> fetchCrops() async {
    setState(() => isLoading = true);

    String apiUrl = '';
    if (dropdownValue == 'My Village') {
      apiUrl =
          '${AppConfig.baseUrl}/sell/filter?filter=my-village&username=${widget.username}';
    } else if (dropdownValue == 'All Villages') {
      apiUrl =
          '${AppConfig.baseUrl}/sell/filter?filter=all-village&username=${widget.username}';
    } else if (dropdownValue == 'My Purchases') {
      apiUrl = '${AppConfig.baseUrl}/buy?buyername=${widget.username}';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          crops = data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        showError(
            'Failed to fetch crops with status code: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error fetching data: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() => isLoading = false);
  }

  void showCropDetails(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CropDetailsPopup(
          crop: crop,
          username: widget.username,
          onInterestSent: fetchCrops, // Refresh data after sending interest
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Dropdown for filtering
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                  fetchCrops(); // Fetch crops on selection change
                });
              },
              items: <String>['My Village', 'All Villages', 'My Purchases']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Display content based on selected filter
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : crops.isEmpty
                    ? Center(child: Text("No data found"))
                    : dropdownValue == 'My Purchases'
                        ? _buildMyPurchasesList()
                        : _buildCropList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCropList() {
    return ListView.builder(
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        String cropImage = cropImageMap[crop['cropname'].toLowerCase()] ??
            'assets/vegetables/default1.jpg'; // Default image if not found
        return ListTile(
          leading:
              Image.asset(cropImage, width: 50, height: 50, fit: BoxFit.cover),
          title: Text(crop['cropname'] ?? 'Unknown Crop'),
          subtitle: Text("₹${crop['price']}"),
          onTap: () => showCropDetails(crop),
        );
      },
    );
  }

  Widget _buildMyPurchasesList() {
    return ListView.builder(
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final purchase = crops[index];
        final isPurchase =
            purchase.containsKey('sell_info'); // Check if this is a purchase
        final cropInfo = isPurchase ? purchase['sell_info'] : purchase;
        return Card(
          child: ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text(cropInfo['cropname'] ?? 'Unknown Crop'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: ₹${cropInfo['price']}"),
                Text("Quantity: ${cropInfo['quantity']}"),
                Text("Seller: ${purchase['sellername']}"),
                Text("Village: ${cropInfo['address']}"),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CropDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> crop;
  final String username;
  final VoidCallback onInterestSent;

  CropDetailsPopup(
      {required this.crop,
      required this.username,
      required this.onInterestSent});

  Future<void> expressInterest(BuildContext context, String buyerUsername,
      String sellerName, String sellId) async {
    final apiUrl = '${AppConfig.baseUrl}/notify';
    final body = json.encode({
      'buyername': buyerUsername, // Pass actual buyer username
      'sellername': sellerName, // Pass actual seller name
      'sell_id': sellId, // Pass the sell ID
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        // Updated for 201 status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notification sent to the seller!")),
        );
        Navigator.pop(context); // Close the popup
        onInterestSent(); // Refresh data (implement as needed)
      } else {
        final responseData = json.decode(response.body);
        //print(responseData);
        throw Exception(responseData['error'] ?? "Failed to send notification");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void callSeller(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw Exception("Could not launch $phoneUri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crop Name and Details
            Text(
              crop['cropname'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Quantity: ${crop['quantity']}"),
            Text("Price: ₹${crop['price']}"),
            Text("Seller: ${crop['sellerDetails']['name']}"),
            Text("Village: ${crop['sellerDetails']['address']}"),
            SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.call),
                  label: Text("Call Seller"),
                  onPressed: () => callSeller(crop['sellerDetails']['phone']),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.notifications),
                  label: Text("Express Interest"),
                  onPressed: () => expressInterest(
                    context,
                    username, // Pass the username from widget
                    crop['sellername'], // Pass the seller's username
                    crop['id'].toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
