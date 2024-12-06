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
        await http.put(
          Uri.parse('${AppConfig.baseUrl}/notify/$notificationId'),
          body: json.encode({'buy': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } else if (action == 'dismiss') {
        await http
            .delete(Uri.parse('${AppConfig.baseUrl}/notify/$notificationId'));
      }
      await fetchNotifications();
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exchange Zone',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff005F3D),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  if (notifications.isNotEmpty) {
                    // Show the list of notifications as before
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                'Notifications',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 300,
                                child: ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    return Card(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 0),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          '${notification['buyername']} is interested in ${notification['cropname']}.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.phone,
                                                  color: Colors.blue),
                                              onPressed: () async {
                                                final String phoneNumber =
                                                    notification['buyerphone'];
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
                                                  if (notifications
                                                          .isNotEmpty &&
                                                      index <
                                                          notifications
                                                              .length) {
                                                    notifications
                                                        .removeAt(index);
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
                                                  if (notifications
                                                          .isNotEmpty &&
                                                      index <
                                                          notifications
                                                              .length) {
                                                    notifications
                                                        .removeAt(index);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
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
                  } else {
                    // Show a popup message saying no new notifications
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Notification',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text('No new notifications available.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
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
                style: TextStyle(color: Colors.white),
              ),
            ),
            Tab(
              child: Text(
                'Buy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          indicatorColor: Colors.white,
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
