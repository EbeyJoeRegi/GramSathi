import 'package:flutter/material.dart';
import '/config.dart';
import 'sell.dart';
import 'buy.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ExchangeZone extends StatefulWidget {
  final String username;

  ExchangeZone({required this.username});

  @override
  _ExchangeZoneState createState() => _ExchangeZoneState();
}

class _ExchangeZoneState extends State<ExchangeZone>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool hasNotification = false;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchNotifications(); // Fetch notifications on init
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/notify?username=${widget.username}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Filter notifications where buy is false and sellername matches the username
          notifications = data
              .where((item) =>
                  item['buy'] == false && item['sellername'] == widget.username)
              .toList();
          hasNotification = notifications.isNotEmpty;
        });
      }
      //print(notifications);
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      print('Could not launch $callUri');
    }
  }

  Future<void> handleNotificationAction(
      String action, int notificationId) async {
    try {
      if (action == 'markAsBought') {
        // Mark as bought API call
        await http.put(
          Uri.parse('${AppConfig.baseUrl}/notify/$notificationId'),
          body: json.encode({'buy': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } else if (action == 'dismiss') {
        // Delete notification API call
        await http
            .delete(Uri.parse('${AppConfig.baseUrl}/notify/$notificationId'));
      }
      await fetchNotifications(); // Refresh notifications
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exchange Zone'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  if (notifications.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              title: Text('Notifications'),
                              content: SizedBox(
                                width: double
                                    .maxFinite, // Ensures proper width constraint
                                height:
                                    300, // Set a fixed or constrained height
                                child: ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    return ListTile(
                                      title: Text(
                                        '${notification['buyername']} is interested in ${notification['cropname']}.',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.phone,
                                                color: Colors.blue),
                                            onPressed: () async {
                                              final String phoneNumber =
                                                  notification[
                                                      'buyerphone']; // Update with the actual phone key
                                              if (phoneNumber.isNotEmpty) {
                                                await makePhoneCall(
                                                    phoneNumber);
                                              } else {
                                                print(
                                                    'Phone number is not available.');
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.check,
                                                color: Colors.green),
                                            onPressed: () async {
                                              await handleNotificationAction(
                                                  'markAsBought',
                                                  notification['id']);
                                              setDialogState(() {
                                                if (notifications.isNotEmpty &&
                                                    index >= 0 &&
                                                    index <
                                                        notifications.length) {
                                                  setDialogState(() {
                                                    notifications
                                                        .removeAt(index);
                                                  });
                                                } else {
                                                  print(
                                                      'Notification list is empty or index is out of range.');
                                                }
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close,
                                                color: Colors.red),
                                            onPressed: () async {
                                              await handleNotificationAction(
                                                  'dismiss',
                                                  notification['id']);
                                              setDialogState(() {
                                                if (notifications.isNotEmpty &&
                                                    index >= 0 &&
                                                    index <
                                                        notifications.length) {
                                                  setDialogState(() {
                                                    notifications
                                                        .removeAt(index);
                                                  });
                                                } else {
                                                  print(
                                                      'Notification list is empty or index is out of range.');
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
              if (hasNotification)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Sell',
                style: TextStyle(color: Colors.black),
              ),
            ),
            Tab(
              child: Text(
                'Buy',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
          indicatorColor: Color(0xff005F3D),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          SellScreen(username: widget.username),
          BuyScreen(username: widget.username),
        ],
      ),
    );
  }
}
