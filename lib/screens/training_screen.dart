import 'package:flutter/material.dart';
import 'package:pethaven/colors.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        title: const Text("Training Activities"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _buildCard("Sit Command", "Teach your pet to sit on command."),
            _buildCard("Stay Command", "Train your pet to stay still."),
            _buildCard("Feeding Routine", "Set consistent feeding times."),
            _buildCard("Exercise", "Daily walk or playtime for 30 mins."),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String subtitle) {
    return Card(
      color: Colors.purple.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
