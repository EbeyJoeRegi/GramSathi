import 'package:flutter/material.dart';
import 'package:GramSathi/screens/admin/admin_announcements_screen.dart';
import 'Village.dart';

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
      AdminAnnouncementPage(
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Village Administrator'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                        Navigator.pushReplacementNamed(
                            context, '/login'); // Navigate to login page
                      },
                      child: Text('Logout'),
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
