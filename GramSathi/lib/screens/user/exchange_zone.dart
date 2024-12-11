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
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 7.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 54.0,
                width: 53.0,
              ),
            ),
            Text(
              'Exchange Zone',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Color(0xff015F3E)),
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
                              title: Center(
                                child: Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: notifications.length <= 5
                                    ? notifications.length * 120.0
                                    : 350.0, // Adjust based on the number of notifications
                                child: notifications.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: notifications.length,
                                        itemBuilder: (context, index) {
                                          final notification =
                                              notifications[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 15),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: Text(
                                                    '${notification['buyername']} is interested in ${notification['cropname']}.',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.phone,
                                                          color: Colors.blue),
                                                      onPressed: () async {
                                                        final String
                                                            phoneNumber =
                                                            notification[
                                                                'buyerphone'];
                                                        if (phoneNumber
                                                            .isNotEmpty) {
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
                                                          if (index <
                                                              notifications
                                                                  .length) {
                                                            notifications
                                                                .removeAt(
                                                                    index);
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
                                                          if (index <
                                                              notifications
                                                                  .length) {
                                                            notifications
                                                                .removeAt(
                                                                    index);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          'No notifications available.',
                                          style: TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
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
                style: TextStyle(
                  color: _tabController.index == 0
                      ? Color(0xFF015F3E) // Active tab color
                      : Color(0xFF015F3E), // Default color (same as active)
                ),
              ),
            ),
            Tab(
              child: Text(
                'Buy',
                style: TextStyle(
                  color: _tabController.index == 1
                      ? Color(0xFF015F3E) // Active tab color
                      : Color(0xFF015F3E), // Default color (same as active)
                ),
              ),
            ),
          ],
          indicatorColor: Color(0xFF015F3E), // Tab indicator color
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
