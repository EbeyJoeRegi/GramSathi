import 'package:flutter/material.dart';
import 'admin_suggestion_screen.dart';
import 'admin_enquiry_screen.dart';
import 'admin_complaints_screen.dart'; // Ensure this is the correct import for complaints

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
            // Padding for the image on the left
            Padding(
              padding: const EdgeInsets.only(right: 7.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 54.0,
                width: 53.0,
              ),
            ),
            // Title text
            Text('Feedback Hub'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Suggestions'),
            Tab(text: 'Enquiry'),
            Tab(text: 'Complaints'),
          ],
          labelColor: Color(0xFF015F3E), // Color for the selected tab
          unselectedLabelColor: Colors.grey, // Color for unselected tabs
          indicatorColor: Color(0xFF015F3E), // Color for the tab indicator
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(), // Disables swiping
        children: [
          AdminSuggestionsScreen(
              username: widget.username), // Pass username to SuggestionsScreen
          AdminEnquiryScreen(
              username: widget.username), // Pass username to EnquiryScreen
          AdminComplaintScreen(
              username: widget.username), // Pass username to ComplaintsScreen
        ],
      ),
    );
  }
}
