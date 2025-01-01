import 'package:flutter/material.dart';
import 'enquiry_screen.dart';
import 'suggestions_screen.dart';
import 'complaints_screen.dart'; // Ensure this is the correct import for complaints

class FeedbackHub extends StatefulWidget {
  final String username; // Add username as a field in FeedbackHub

  FeedbackHub({required this.username}); // Constructor to accept username

  @override
  _FeedbackHubState createState() => _FeedbackHubState();
}

class _FeedbackHubState extends State<FeedbackHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the controller to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(width: 5),
            const Text(
              'Feedback Hub',
              style: TextStyle(
                color: Colors.black, // Set the text color to black
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Suggestions',
                style:
                    TextStyle(color: Colors.black), // Set text color to black
              ),
            ),
            Tab(
              child: Text(
                'Enquiry',
                style:
                    TextStyle(color: Colors.black), // Set text color to black
              ),
            ),
            Tab(
              child: Text(
                'Complaints',
                style:
                    TextStyle(color: Colors.black), // Set text color to black
              ),
            ),
          ],
          indicatorColor: Color(0xff005F3D),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(), // Disables swiping
        children: [
          SuggestionsScreen(
              username: widget.username), // Pass username to SuggestionsScreen
          EnquiryScreen(
              username: widget.username), // Pass username to EnquiryScreen
          ComplaintsScreen(
              username: widget.username), // Pass username to ComplaintsScreen
        ],
      ),
    );
  }
}
