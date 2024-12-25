import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '/config.dart';

class MarketUpdatesScreen extends StatefulWidget {
  final String username;

  MarketUpdatesScreen({required this.username});
  @override
  _MarketUpdatesScreenState createState() => _MarketUpdatesScreenState();
}

class _MarketUpdatesScreenState extends State<MarketUpdatesScreen> {
  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _crops = [];
  List<Map<String, dynamic>> _allCrops = [];
  int _selectedPlaceId = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _fetchAllCrops();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch user address and ID based on username
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/address?username=${widget.username}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          // Update places with the response data
          _places = [
            {
              'id': data['id'],
              'place_name': data['address'],
            }
          ];
          // Select the place ID
          _selectedPlaceId = data['id'] ?? 0;

          // Fetch crops related to the selected place
          _fetchCropsByPlace(_selectedPlaceId);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load address';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCropsByPlace(int placeId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/crops/$placeId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _crops = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load crops';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllCrops() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/all-crops'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allCrops = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to load all crops');
      }
    } catch (e) {
      print('An error occurred. Please try again later.');
    }
  }

  void _showEditPriceDialog(Map<String, dynamic> crop) {
    final TextEditingController _priceController =
        TextEditingController(text: crop['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Price'),
          content: TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price',
              labelStyle: TextStyle(color: Color(0xff015F3E)),
              border: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xff015F3E)), // Border color
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xff015F3E)), // Border color
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xff015F3E)), // Border color
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            cursorColor: Color(0xff015F3E), // Cursor color
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xff015F3E))),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCropPrice(
                    crop['id'], double.parse(_priceController.text));
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(color: Color(0xff015F3E)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCropPrice(int cropId, double newPrice) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/update-price/$cropId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'id': cropId,
        'price': newPrice,
        'month_year': DateFormat('MMMM yyyy').format(DateTime.now()),
      }),
    );

    if (response.statusCode == 200) {
      _fetchCropsByPlace(_selectedPlaceId);
    } else {
      print('Failed to update crop price');
    }
  }

  void _showAddPriceDialog() {
    final TextEditingController _priceController = TextEditingController();
    int? _selectedCropId;
    int? _selectedPlaceIdForAdd = _selectedPlaceId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Price'),
              content: FutureBuilder(
                future: _fetchAllCrops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Failed to load crops'));
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Place Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: DropdownButton<int>(
                              value: _selectedPlaceIdForAdd,
                              hint: Text('Select Place'),
                              items:
                                  _places.map<DropdownMenuItem<int>>((place) {
                                return DropdownMenuItem<int>(
                                  value: place['id'],
                                  child: Text(place['place_name']),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedPlaceIdForAdd = newValue;
                                });
                              },
                            ),
                          ),

                          // Crop Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    8.0), // Rounded corners
                                border: Border.all(
                                  color: Color(0xff015F3E), // Border color
                                  width: 1.0, // Border width
                                ),
                              ),
                              child: DropdownButton<int>(
                                value: _selectedCropId,
                                hint: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Select Crop'),
                                ),
                                items: _allCrops
                                    .map<DropdownMenuItem<int>>((crop) {
                                  return DropdownMenuItem<int>(
                                    value: crop['id'],
                                    child: Text(crop['crop_name']),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedCropId = newValue;
                                  });
                                },
                                isExpanded:
                                    true, // Ensures the dropdown takes up the full width of the container
                                underline:
                                    SizedBox(), // Hides the default underline of the dropdown button
                              ),
                            ),
                          ),

                          // Price Input Field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: _priceController,
                              cursorColor:
                                  Color(0xff015F3E), // Set cursor color
                              decoration: InputDecoration(
                                labelText: 'Price',
                                labelStyle: TextStyle(color: Colors.black),
                                //filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                      color: Color(0xff015F3E),
                                      width: 1.2), // Default border color
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                      color: Color(0xff015F3E),
                                      width: 1.2), // Border when enabled
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                      color: Color(0xff015F3E),
                                      width: 1.2), // Border when focused
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xff015F3E)),
                  ),
                ),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCropId != null &&
                        _selectedPlaceIdForAdd != null &&
                        _priceController.text.isNotEmpty) {
                      _addCropPrice(
                        _selectedCropId!,
                        _selectedPlaceIdForAdd!,
                        double.parse(_priceController.text),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Color(0xff015F3E)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCropPrice(int cropId, int placeId, double price) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/add-price'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'crop_id': cropId,
          'place_id': placeId,
          'price': price,
          'month_year': DateFormat('MMMM yyyy').format(DateTime.now()),
        }),
      );

      if (response.statusCode == 200) {
        _fetchCropsByPlace(placeId);
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(responseData['error']);
      } else {
        print('Failed to add crop price');
      }
    } catch (e) {
      print('An error occurred. Please try again later.');
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPopupMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Update Average'),
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateAverageDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add New Crop'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCropDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateAverageDialog() {
    final TextEditingController _averagePriceController =
        TextEditingController();
    int? _selectedCropId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Average Price'),
              content: FutureBuilder(
                future: _fetchAllCrops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Failed to load crops'));
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dropdown Field
                        DropdownButtonFormField<int>(
                          value: _selectedCropId,
                          hint: Text('Select Crop'),
                          items: _allCrops.map<DropdownMenuItem<int>>((crop) {
                            return DropdownMenuItem<int>(
                              value: crop['id'],
                              child: Text(crop['crop_name']),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedCropId = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color:
                                    Color(0xff015F3E), // Default border color
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Color(0xff015F3E), // Enabled border
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Color(0xff015F3E), // Focused border
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Text Field
                        TextField(
                          controller: _averagePriceController,
                          cursorColor: Color(0xff015F3E), // Set cursor color
                          decoration: InputDecoration(
                            labelText: 'Average Price',
                            labelStyle: TextStyle(color: Color(0xff015F3E)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color:
                                    Color(0xff015F3E), // Default border color
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Color(0xff015F3E), // Enabled border
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Color(0xff015F3E), // Focused border
                                width: 2.0,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    );
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xff015F3E)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCropId != null &&
                        _averagePriceController.text.isNotEmpty) {
                      _updateAveragePrice(
                        _selectedCropId!,
                        double.parse(_averagePriceController.text),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Color(0xff015F3E)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateAveragePrice(int cropId, double averagePrice) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/update-average-price'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'crop_id': cropId,
        'average_price': averagePrice,
      }),
    );

    if (response.statusCode == 200) {
      _fetchCropsByPlace(_selectedPlaceId);
    } else {
      print('Failed to update average price');
    }
  }

  void _showAddCropDialog() {
    final TextEditingController _cropNameController = TextEditingController();
    final TextEditingController _averagePriceController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Crop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cropNameController,
                cursorColor: Color(0xff015F3E), // Cursor color
                decoration: InputDecoration(
                  labelText: 'Crop Name',
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xff015F3E)), // Border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xff015F3E)), // Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xff015F3E),
                        width: 2.0), // Border when focused
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _averagePriceController,
                cursorColor: Color(0xff015F3E), // Cursor color
                decoration: InputDecoration(
                  labelText: 'Average Price',
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xff015F3E)), // Border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xff015F3E)), // Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xff015F3E),
                        width: 2.0), // Border when focused
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Color(0xff015F3E)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_cropNameController.text.isNotEmpty &&
                    _averagePriceController.text.isNotEmpty) {
                  _addNewCrop(
                    _cropNameController.text,
                    double.parse(_averagePriceController.text),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: Color(0xff015F3E)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewCrop(String cropName, double averagePrice) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/add-crop'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'crop_name': cropName,
          'avg_price': averagePrice,
        }),
      );

      if (response.statusCode == 200) {
        _fetchAllCrops();
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(responseData['error']);
      } else {
        print('Failed to add new crop');
      }
    } catch (e) {
      print('An error occurred. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Place'),
        backgroundColor: Color(0xffE6F4E3),
      ),
      body: Container(
        color: Color(0xffE6F4E3),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField<int>(
                          value: _selectedPlaceId,
                          hint: Text('Select Location'),
                          items: _places.map<DropdownMenuItem<int>>((place) {
                            return DropdownMenuItem<int>(
                              value: place['id'],
                              child: Text(place['place_name']),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedPlaceId = newValue!;
                              _fetchCropsByPlace(_selectedPlaceId);
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _crops.length,
                          itemBuilder: (context, index) {
                            final crop = _crops[index];
                            return Container(
                              margin: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    16.0), // Circular border
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF015F3E)
                                        .withOpacity(0.5), // Shadow color
                                    blurRadius: 8.0, // Blur effect
                                    offset: Offset(0, 4), // Shadow offset
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  crop['crop_name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight
                                          .w500), // Makes the text bold
                                ),
                                subtitle: Text(
                                    'Price: ${crop['price']}\nAverage Price: ${crop['avg_price']}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _showEditPriceDialog(crop);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'updateAverage',
            onPressed: _showPopupMenu,
            child: Icon(
              Icons.more_vert,
              color: Color(0xFF001F14),
            ),
            backgroundColor:
                Color(0xFF55947E).withOpacity(0.9), // Set background color
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addCropPrice',
            onPressed: _showAddPriceDialog,
            child: Icon(
              Icons.add,
              color: Color(0xFF001F14),
            ),
            backgroundColor:
                Color(0xFF55947E).withOpacity(0.9), // Set background color
          ),
        ],
      ),
    );
  }
}
