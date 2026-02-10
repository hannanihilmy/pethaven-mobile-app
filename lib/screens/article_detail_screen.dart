import 'package:flutter/material.dart';
import 'package:pethaven/colors.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String body;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0288D1);
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Pet Care Tip 💙"),
        backgroundColor: blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.pets, color: blue, size: 80),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
