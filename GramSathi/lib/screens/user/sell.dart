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
  String selectedUnit = '/kg';
  String selectedPriceUnit = 'kg';
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Map to associate crop names with image paths (all lowercase keys)
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

  @override
  void initState() {
    super.initState();
    fetchCrops();
  }

  void fetchCrops() async {
    final response = await fetchCropsFromApi(dropdownValue == "Items for Sale");
    setState(() {
      crops = response;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCropsFromApi(bool isForSale) async {
    final apiUrl = isForSale
        ? "${AppConfig.baseUrl}/sell?sold=false&sellername=${widget.username}"
        : "${AppConfig.baseUrl}/sell?sold=true&sellername=${widget.username}";

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Add New Crop",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildInputField(cropNameController, "Crop Name", Icons.grain),
                SizedBox(height: 10),

                // Quantity input with dropdown for unit selection
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: "Quantity",
                          prefixIcon: Icon(Icons.bar_chart),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedPriceUnit,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPriceUnit = newValue!;
                        });
                      },
                      items: <String>['kg', 'gram', 'bunch']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      icon: Icon(Icons.arrow_drop_down),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Price input with dropdown for unit selection
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: "Price",
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedUnit,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedUnit = newValue!;
                        });
                      },
                      items: <String>['/kg', '/gram', '/bunch']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      icon: Icon(Icons.arrow_drop_down),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                // Make sure the state values are used correctly when adding a crop
                addNewCrop(
                  cropNameController.text,
                  double.tryParse(quantityController.text) ?? 0,
                  double.tryParse(priceController.text) ?? 0.0,
                );
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  TextField buildInputField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
    );
  }

  void addNewCrop(String cropName, double quantity, double price) async {
    final payload = {
      "sellername": widget.username,
      "cropname": cropName,
      "quantity": quantity,
      "price": price,
      'unit': selectedUnit,
    };

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/sell"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      fetchCrops();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Crop added successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add crop")),
      );
    }
  }

  void showCropDetailsPopup(BuildContext context, Map<String, dynamic> crop) {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Crop Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text("Crop Name"),
                subtitle: Text(crop["cropname"]),
              ),
              ListTile(
                title: Text("Quantity"),
                subtitle:
                    Text("${crop["quantity"]} ${crop["selectedPriceUnit"]}"),
              ),
              ListTile(
                title: Text("Price"),
                subtitle: Text("\₹${crop["price"]} ${crop["selectedUnit"]}"),
              ),
              if (!crop["sold"])
                ElevatedButton(
                  onPressed: () {
                    markAsSold(crop["id"]);
                  },
                  child: Text("Mark as Sold"),
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
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      fetchCrops();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Crop marked as sold successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark crop as sold")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sell Crops")),
      body: Column(
        children: [
          buildDropdown(),
          isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: crops.length,
                    itemBuilder: (context, index, animation) {
                      final crop = crops[index];
                      return buildCropCard(crop, animation);
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddCropPopup(context),
        label: Text("Add Crop"),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10), // Rounded edges
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400, // Shadow color
              blurRadius: 5.0, // Softness of the shadow
              offset: Offset(0, 3), // Offset of the shadow (x, y)
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 15.0), // Add padding inside container
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          underline: SizedBox(), // Remove default underline
          items: ["Items for Sale", "Sold Items"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis, // Prevent overflow text
                maxLines: 1, // Ensure single line
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
              isLoading = true;
            });
            fetchCrops();
          },
          dropdownColor: Colors.white, // Background color of dropdown
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }

  Widget buildCropCard(Map<String, dynamic> crop, Animation<double> animation) {
    return FadeTransition(
        opacity: animation,
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30, // Increased the radius for a larger image
              backgroundImage: AssetImage(
                cropImageMap[crop["cropname"].toLowerCase()] ??
                    'assets/vegetables/default1.jpg',
              ),
            ),
            title: Text(crop["cropname"]),
            subtitle: Text(
              "Price: ₹${crop["price"]} ${crop["unit"] ?? '/kg'}", // Show unit selected by user
            ),
            trailing:
                crop["sold"] ? Icon(Icons.check, color: Colors.green) : null,
            onTap: () => showCropDetailsPopup(context, crop),
          ),
        ));
  }
}
