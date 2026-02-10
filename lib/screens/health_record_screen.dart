// lib/screens/health_record_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pethaven/colors.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});
  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _symptomCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  Future<void> _save() async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('health_records')
        .add({
      'symptom': _symptomCtrl.text.trim(),
      'treatment': _treatmentCtrl.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Health record saved')));
    _symptomCtrl.clear();
    _treatmentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).primaryColor;
    return Scaffold(
      appBar:
          AppBar(title: const Text('Health Records'), backgroundColor: blue),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
                controller: _symptomCtrl,
                decoration:
                    const InputDecoration(labelText: 'Symptoms / Notes')),
            const SizedBox(height: 10),
            TextField(
                controller: _treatmentCtrl,
                decoration:
                    const InputDecoration(labelText: 'Treatment / Vet Advice')),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: blue),
                child: const Text('Save')),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Records',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: _buildRecordsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_user == null) return const Center(child: Text('Please login'));
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('health_records')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No records'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final timeStr = d['timestamp'] != null
                ? (d['timestamp'] as Timestamp).toDate().toString()
                : '';
            return Card(
              child: ListTile(
                title: Text(d['symptom'] ?? 'No info'),
                subtitle: Text('${d['treatment'] ?? ''}\n$timeStr'),
              ),
            );
          },
        );
      },
    );
  }
}
