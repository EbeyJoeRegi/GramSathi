import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/config.dart';
import 'dart:convert';

class SellScreen extends StatefulWidget {
  final String username;
  SellScreen({required this.username});
  @override
  _SellScreenState createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  String dropdownValue = "Items for Sale";
  List<Map<String, dynamic>> crops = []; // Store crops fetched from API
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCrops(); // Fetch crops when the screen loads
  }

  void fetchCrops() async {
    // Fetch crops from the API
    final response = await fetchCropsFromApi(dropdownValue == "Items for Sale");
    setState(() {
      crops = response;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCropsFromApi(bool isForSale) async {
    // Replace with your API URL
    final apiUrl = isForSale
        ? "${AppConfig.baseUrl}/sell?sold=false&sellername=${widget.username}"
        : "${AppConfig.baseUrl}/sell?sold=true&sellername=${widget.username}";

    // API call logic here
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load crops");
    }
  }

  void showAddCropPopup(BuildContext context) {
    final TextEditingController cropNameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Crop"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crop Name Input
                TextField(
                  controller: cropNameController,
                  decoration: InputDecoration(
                    labelText: "Crop Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                // Quantity Input
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                // Price Input
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            // Submit Button
            ElevatedButton(
              onPressed: () {
                addNewCrop(
                  cropNameController.text,
                  double.tryParse(quantityController.text) ?? 0,
                  double.tryParse(priceController.text) ?? 0.0,
                );
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void addNewCrop(String cropName, double quantity, double price) async {
    final payload = {
      "sellername":
          widget.username, // Use the dynamic username passed to SellScreen
      "cropname": cropName,
      "quantity": quantity,
      "price": price,
    };

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/sell"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      fetchCrops(); // Refresh the crop list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Crop added successfully")),
      );
    } else {
      print("Error: ${response.statusCode}");
      print("Response Body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add crop: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sell Crops")),
      body: Column(
        children: [
          // Dropdown for filtering
          DropdownButton<String>(
            value: dropdownValue,
            items: ["Items for Sale", "Sold Items"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                dropdownValue = newValue!;
                isLoading = true;
              });
              fetchCrops();
            },
          ),
          // List of crops
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      return ListTile(
                        leading: Icon(Icons.local_florist), // Default crop icon
                        title: Text(crop["cropname"]),
                        subtitle: Text("Price: \$${crop["price"]}"),
                        onTap: () {
                          // Open fullscreen popup with crop details
                          showCropDetailsPopup(context, crop);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      // Floating button to add a new crop
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddCropPopup(context); // Open a popup for adding a new crop
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showCropDetailsPopup(BuildContext context, Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SingleChildScrollView(
          child: Column(
            children: [
              Text("Crop Details", style: TextStyle(fontSize: 20)),
              ListTile(
                title: Text("Crop Name"),
                subtitle: Text(crop["cropname"]),
              ),
              ListTile(
                title: Text("Quantity"),
                subtitle: Text("${crop["quantity"]}"),
              ),
              ListTile(
                title: Text("Price"),
                subtitle: Text("\$${crop["price"]}"),
              ),
              if (!crop["sold"]) // Mark as sold option
                ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      markAsSold(crop["id"]);
                    },
                    child: Text("Mark as Sold"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void markAsSold(int cropId) async {
    final response = await http.put(
      Uri.parse("${AppConfig.baseUrl}/sell/$cropId"),
      headers: {"Content-Type": "application/json"}, // Include headers
    );

    if (response.statusCode == 200) {
      fetchCrops(); // Refresh the crop list after marking as sold
      Navigator.pop(context); // Close the popup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Crop marked as sold successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark crop as sold")),
      );
    }
  }
}
