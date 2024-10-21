import 'package:flutter/material.dart';

class ComplaintsScreen extends StatelessWidget {
  final String username;

  ComplaintsScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Complaints for $username'), // Use the username
      ),
    );
  }
}
