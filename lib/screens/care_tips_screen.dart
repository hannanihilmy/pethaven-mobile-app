// lib/screens/care_tips_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pethaven/colors.dart';

class CareTipsScreen extends StatefulWidget {
  const CareTipsScreen({super.key});
  @override
  State<CareTipsScreen> createState() => _CareTipsScreenState();
}

class _CareTipsScreenState extends State<CareTipsScreen> {
  List<dynamic> tips = [];

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    final s = await rootBundle.loadString('assets/advice.json');
    setState(() => tips = json.decode(s));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Care Tips'),
          backgroundColor: Theme.of(context).primaryColor),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tips.length,
        itemBuilder: (context, i) {
          final tip = tips[i] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.star),
              title: Text(tip['title'] ?? ''),
              subtitle: Text(tip['body'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
