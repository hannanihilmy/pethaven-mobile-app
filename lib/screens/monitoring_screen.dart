import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pethaven/colors.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final TextEditingController feedingController = TextEditingController();
  final TextEditingController exerciseController = TextEditingController();
  final TextEditingController healthController = TextEditingController();
  final TextEditingController moodController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> saveMonitoringData() async {
    if (_user == null) return;

    try {
      await _firestore.collection('monitoring').add({
        'userId': _user.uid,
        'feeding': feedingController.text.trim(),
        'exercise': exerciseController.text.trim(),
        'health': healthController.text.trim(),
        'mood': moodController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monitoring data saved successfully!')),
      );

      // Clear text fields
      feedingController.clear();
      exerciseController.clear();
      healthController.clear();
      moodController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Monitoring 🐾'),
        backgroundColor: const Color(0xFF8B5CF6),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInputField("Feeding", feedingController),
              _buildInputField("Exercise", exerciseController),
              _buildInputField("Health", healthController),
              _buildInputField("Mood", moodController),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: saveMonitoringData,
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              const Text(
                "Previous Records",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
              const SizedBox(height: 10),
              _buildMonitoringList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildMonitoringList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('monitoring')
          .where('userId', isEqualTo: _user?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.docs;

        if (data.isEmpty) {
          return const Text("No monitoring records yet.");
        }

        return Column(
          children: data.map((doc) {
            final record = doc.data() as Map<String, dynamic>;
            final timestamp =
                record['timestamp']?.toDate()?.toString() ?? 'Unknown time';
            return Card(
              color: Colors.purple.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.pets, color: Colors.deepPurple),
                title: Text(
                    "Health: ${record['health']} | Mood: ${record['mood']}"),
                subtitle: Text(
                    "Feeding: ${record['feeding']}\nExercise: ${record['exercise']}\n$timestamp"),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
