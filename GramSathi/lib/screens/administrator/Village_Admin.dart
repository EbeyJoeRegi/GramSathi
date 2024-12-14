import 'package:flutter/material.dart';
import 'village_announcements_screen.dart';
import 'Village_Infos.dart';

class VillageAdminPage extends StatefulWidget {
  final String username;
  VillageAdminPage({required this.username});

  @override
  _VillageAdminPageState createState() => _VillageAdminPageState();
}

class _VillageAdminPageState extends State<VillageAdminPage> {
  int _selectedIndex = 0;

  // Declare _pages without initializing it here
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize the _pages list inside initState
    _pages = [
      VillageAnnouncementPage(
          username: widget.username), // Same as that of admin announcement
      VillagePage(),
    ];
  }

  // Method to handle bottom navigation tab changes
  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color(0xFFE6F4E3), // Set the background color of the body
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 53.0,
                width: 52.0,
              ),
            ),
            Text(
              'Village Administrator',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold, // Make text bold
              ),
            ),
          ],
        ),
        backgroundColor:
            Colors.white, // Use soft green for the AppBar background
        elevation: 0, // Optional: Remove the shadow to make it cleaner
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: Colors.black), // Customize logout icon color
            onPressed: () {
              // Add logout functionality here
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context), // Close the dialog
                      child: Text('Cancel',
                          style: TextStyle(color: Color(0xff015F3E))),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                        Navigator.pushReplacementNamed(
                            context, '/login'); // Navigate to login page
                      },
                      child: Text('Logout',
                          style: TextStyle(color: Color(0xff015F3E))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: Color(0xFF015F3E), // Custom color for selected index
        unselectedItemColor: Colors.black, // Color for unselected items
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Village',
          ),
        ],
      ),
    );
  }
}
