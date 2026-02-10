import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pethaven/services/notification_service.dart';
import 'package:pethaven/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ReminderScreen extends StatefulWidget {
  final String selectedPetId;
  const ReminderScreen({super.key, required this.selectedPetId});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _pickedTime;
  String _type = 'Feeding';
  String? _medicationType;
  String? _vaccineType;
  DateTime? _adminDate;
  DateTime? _expiryDate;
  String? _uploadedFileUrl;

  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  String _sortUpcoming = 'Date (Newest)';
  String _sortPast = 'By Month';
  String _searchUpcoming = '';
  String _searchPast = '';

  // ---------------------- PICKERS ----------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _pickedTime = picked);
  }

  Future<void> _pickAdminDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _adminDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _adminDate = picked);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  // ---------------------- FILE UPLOAD ----------------------

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final ref = FirebaseStorage.instance.ref().child(
          "reminder_files/${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}");

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() => _uploadedFileUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File uploaded successfully!'),
          backgroundColor: kSuccessColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  // ---------------------- SAVE REMINDER ----------------------

  Future<void> _saveReminder() async {
    if (_selectedDate == null || _pickedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Select both date and time first."),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _pickedTime!.hour,
      _pickedTime!.minute,
    );

    final doc = await _firestore.collection("reminders").add({
      "userId": _user!.uid,
      "petId": widget.selectedPetId,
      "title": _titleCtrl.text.trim(),
      "notes": _notesCtrl.text.trim(),
      "type": _type,
      "medicationType": _medicationType,
      "vaccineType": _vaccineType,
      "adminDate": _adminDate?.toIso8601String(),
      "expiryDate": _expiryDate?.toIso8601String(),
      "fileUrl": _uploadedFileUrl,
      "datetime": dateTime.toIso8601String(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    // Schedule notification
    await NotificationService.scheduleOneTime(
      id: doc.id.hashCode & 0x7fffffff,
      title: "Reminder: ${_titleCtrl.text}",
      body: "It's time for ${_type.toLowerCase()}! 🐾",
      scheduledTime: dateTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Reminder saved & scheduled!"),
        backgroundColor: kSuccessColor,
      ),
    );

    _titleCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _selectedDate = null;
      _pickedTime = null;
      _uploadedFileUrl = null;
      _medicationType = null;
      _vaccineType = null;
      _adminDate = null;
      _expiryDate = null;
    });
  }

  // ---------------------- EDIT ----------------------

  Future<void> _editReminder(String id, Map<String, dynamic> data) async {
    _titleCtrl.text = data["title"];
    _notesCtrl.text = data["notes"] ?? "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBackground,
        title: const Text("Edit Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: "Notes"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("reminders").doc(id).update({
                "title": _titleCtrl.text.trim(),
                "notes": _notesCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------------- DELETE ----------------------

  Future<void> _deleteReminder(String id) async {
    await _firestore.collection("reminders").doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Reminder deleted"),
        backgroundColor: kErrorColor,
      ),
    );
  }

  // ---------------------- QUERY ----------------------

  Query<Map<String, dynamic>> _mainQuery() {
    return _firestore
        .collection("reminders")
        .where("userId", isEqualTo: _user!.uid)
        .where("petId", isEqualTo: widget.selectedPetId)
        .orderBy("datetime", descending: true);
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kAccentColor,
        centerTitle: true,
        title: const Text("Reminders 🕒",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              NotificationService.showNow(
                "Test Notification",
                "Notifications are working! 🎉",
              );
            },
            icon: const Icon(Icons.notifications_active, color: Colors.white),
          ),
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddReminderCard(),
            const SizedBox(height: 25),

// 🌿 FIXED RESPONSIVE UPCOMING FILTER CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  // SEARCH BAR
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                        hintText: "Search upcoming...",
                        hintStyle: TextStyle(
                          color: kTextMain.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchUpcoming = v),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // SORT DROPDOWN (SHRINKS ON SMALL SCREEN)
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _sortUpcoming,
                      isDense: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Sort",
                        labelStyle: TextStyle(
                          color: kTextMain.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "Date (Newest)", child: Text("Newest")),
                        DropdownMenuItem(
                            value: "Date (Oldest)", child: Text("Oldest")),
                        DropdownMenuItem(
                            value: "Alphabetical (A-Z)", child: Text("A → Z")),
                        DropdownMenuItem(
                            value: "Alphabetical (Z-A)", child: Text("Z → A")),
                      ],
                      onChanged: (v) => setState(() => _sortUpcoming = v!),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: const [
                Text(
                  "📆 Upcoming Reminders",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kTextMain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              thickness: 1.2,
              color: kPrimaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 10),
            _buildReminderList(showPast: false),

            const SizedBox(height: 25),

            // 🌿 FINAL FIX – NEVER OVERFLOWS (PAST FILTER)
            Row(
              children: const [
                Text(
                  "📜 Past Reminders",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kTextMain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              thickness: 1.2,
              color: kAccentColor.withOpacity(0.3),
            ),
            const SizedBox(height: 15),
            // 🌿 FIXED PAST FILTER CARD (NO OVERFLOW EVER)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  // SEARCH BAR
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                        hintText: "Search past...",
                        hintStyle: TextStyle(
                          color: kTextMain.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchPast = v),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // SORT DROPDOWN
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _sortPast,
                      isDense: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Sort",
                        labelStyle: TextStyle(
                          color: kTextMain.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "By Month", child: Text("Month")),
                        DropdownMenuItem(
                            value: "Alphabetical (A-Z)", child: Text("A → Z")),
                        DropdownMenuItem(
                            value: "Alphabetical (Z-A)", child: Text("Z → A")),
                      ],
                      onChanged: (v) => setState(() => _sortPast = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _buildReminderList(showPast: true),
          ],
        ),
      ),
    );
  }

  Widget _bubbleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cuteButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
    EdgeInsets padding =
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ---------------------- REMINDER LIST ----------------------

  Widget _buildReminderList({required bool showPast}) {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: _mainQuery().snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        // FILTERING
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final dt = DateTime.parse(data["datetime"]);
          final search =
              (showPast ? _searchPast : _searchUpcoming).toLowerCase();
          final searchable = "${data["title"]} ${data["type"]}".toLowerCase();
          final matches = searchable.contains(search);

          return showPast
              ? dt.isBefore(now) && matches
              : dt.isAfter(now) && matches;
        }).toList();

        // SORTING
        if (showPast) {
          if (_sortPast == "Month") {
            filtered.sort((a, b) {
              final ad = DateTime.parse((a.data() as Map)["datetime"]);
              final bd = DateTime.parse((b.data() as Map)["datetime"]);
              return bd.month.compareTo(ad.month);
            });
          } else if (_sortPast == "Alphabetical (A-Z)") {
            filtered
                .sort((a, b) => (a["title"] ?? "").compareTo(b["title"] ?? ""));
          } else {
            filtered
                .sort((a, b) => (b["title"] ?? "").compareTo(a["title"] ?? ""));
          }
        } else {
          if (_sortUpcoming == "Date (Newest)") {
            filtered.sort((a, b) {
              final ad = DateTime.parse((a.data() as Map)["datetime"]);
              final bd = DateTime.parse((b.data() as Map)["datetime"]);
              return bd.compareTo(ad);
            });
          } else if (_sortUpcoming == "Date (Oldest)") {
            filtered.sort((a, b) {
              final ad = DateTime.parse((a.data() as Map)["datetime"]);
              final bd = DateTime.parse((b.data() as Map)["datetime"]);
              return ad.compareTo(bd);
            });
          } else if (_sortUpcoming == "Alphabetical (A-Z)") {
            filtered
                .sort((a, b) => (a["title"] ?? "").compareTo(b["title"] ?? ""));
          } else {
            filtered
                .sort((a, b) => (b["title"] ?? "").compareTo(a["title"] ?? ""));
          }
        }

        // EMPTY STATE
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              showPast ? "No past reminders." : "No upcoming reminders.",
              style: const TextStyle(color: kTextSecondary),
            ),
          );
        }

        // CARD BUILDER
        return Column(
          children: filtered.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final title = data["title"];
            final type = data["type"];
            final notes = data["notes"] ?? "";
            final datetime = DateFormat("MMM d, yyyy • hh:mm a")
                .format(DateTime.parse(data["datetime"]));

            // ICON & TAG COLOR
            IconData icon = Icons.alarm;
            Color tagColor = kPrimaryColor;

            if (type == "Feeding") {
              icon = Icons.pets;
              tagColor = const Color(0xFF8BC34A); // matcha lime
            } else if (type == "Medication") {
              icon = Icons.medical_services_rounded;
              tagColor = const Color(0xFFF06292); // strawberry pink
            } else if (type == "Vet Appointment") {
              icon = Icons.local_hospital;
              tagColor = const Color(0xFF42A5F5); // soft blue
            }

            return Dismissible(
              key: Key(d.id),
              direction: DismissDirection.endToStart,
              background: Container(
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: kErrorColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 30),
              ),
              onDismissed: (_) => _deleteReminder(d.id),
              child: GestureDetector(
                onTap: () => _showReminderDetails(d.id, data),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: tagColor.withOpacity(0.25),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ICON BUBBLE
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: tagColor, size: 26),
                      ),

                      const SizedBox(width: 14),

                      // TEXT AREA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TITLE
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTextMain,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // TYPE TAG
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: tagColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // DATE + NOTES
                            Text(
                              datetime,
                              style: const TextStyle(
                                  fontSize: 14, color: kTextSecondary),
                            ),

                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                notes,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // EDIT BUTTON
                      IconButton(
                        icon: const Icon(Icons.edit, color: kAccentColor),
                        onPressed: () => _editReminder(d.id, data),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------------- DETAILS POPUP ----------------------

  void _showReminderDetails(String id, Map<String, dynamic> data) async {
    final title = data["title"];
    final notes = data["notes"] ?? "";
    final type = data["type"];
    final file = data["fileUrl"];
    final datetime = DateFormat("MMM d, yyyy • hh:mm a")
        .format(DateTime.parse(data["datetime"]));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBackground,
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Type: $type", style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 6),
            Text("Date & Time: $datetime",
                style: const TextStyle(color: kTextSecondary)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text("Notes: $notes",
                  style: const TextStyle(color: kTextSecondary)),
            ],
            if (file != null)
              TextButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text("Open attached file"),
                onPressed: () async {
                  final uri = Uri.parse(file);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: kAccentColor)),
          )
        ],
      ),
    );
  }

  // ---------------------- ADD REMINDER UI ----------------------

  Widget _buildAddReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE: Add Reminder
          const Text(
            "Add Reminder ✨",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kTextMain,
            ),
          ),

          const SizedBox(height: 20),

          // ===================== REMINDER TYPE =====================
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white, // dropdown background
              cardColor: Colors.white, // ensures it stays white
              brightness: Brightness.light, // force light theme
            ),
            child: DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: Colors.white,
              decoration: _bubbleFieldDecoration("Reminder type"),
              iconEnabledColor: kTextMain,
              style: const TextStyle(
                color: kTextMain, // readable text
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(
                  value: "Feeding",
                  child: Text("🍽 Feeding"),
                ),
                DropdownMenuItem(
                  value: "Medication",
                  child: Text("💊 Medication"),
                ),
                DropdownMenuItem(
                  value: "Vet Appointment",
                  child: Text("🐾 Vet Appointment"),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),

          const SizedBox(height: 15),

          // ===================== MEDICATION SUB-TYPE =====================
          if (_type == "Medication") ...[
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white, // dropdown background
              ),
              child: DropdownButtonFormField<String>(
                value: _medicationType,
                decoration: _bubbleFieldDecoration("Medication type"),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: kTextMain, // readable text
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(
                      value: "Vaccination", child: Text("💉 Vaccination")),
                  DropdownMenuItem(
                      value: "Deworming", child: Text("🐛 Deworming")),
                  DropdownMenuItem(
                      value: "Flea & Tick Treatment",
                      child: Text("🕷 Flea & Tick Treatment")),
                  DropdownMenuItem(value: "Other", child: Text("✨ Other")),
                ],
                onChanged: (v) => setState(() => _medicationType = v),
              ),
            ),
            const SizedBox(height: 12),
            if (_medicationType == "Vaccination")
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white, // dropdown menu background
                  cardColor: Colors.white,
                  brightness: Brightness.light, // force light mode dropdown
                ),
                child: DropdownButtonFormField<String>(
                  value: _vaccineType,
                  dropdownColor: Colors.white,
                  iconEnabledColor: kTextMain,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _bubbleFieldDecoration("Vaccine type"),
                  items: const [
                    DropdownMenuItem(
                      value: "Rabies",
                      child: Text("🐶 Rabies"),
                    ),
                    DropdownMenuItem(
                      value: "FVRCP",
                      child: Text("🐱 FVRCP"),
                    ),
                    DropdownMenuItem(
                      value: "Bordetella",
                      child: Text("🦴 Bordetella"),
                    ),
                  ],
                  onChanged: (v) => setState(() => _vaccineType = v),
                ),
              )
          ],

          const SizedBox(height: 20),

          // ===================== TITLE =====================
          const Text("Title",
              style: TextStyle(
                  color: kTextSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: kTextMain),
            decoration: _bubbleInputDecoration("Enter reminder title…"),
          ),

          const SizedBox(height: 20),

          // ===================== NOTES =====================
          const Text("Notes (optional)",
              style: TextStyle(
                  color: kTextSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: kTextMain),
            maxLines: 2,
            decoration: _bubbleInputDecoration("Add extra details…"),
          ),

          const SizedBox(height: 20),

          // ===================== DATE & TIME PICKERS =====================
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _pickDate,
                  style: _matchaBubbleButton(),
                  child: Text(
                    _selectedDate == null
                        ? "Pick Date"
                        : DateFormat("MMM d, yyyy").format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _pickTime,
                  style: _matchaBubbleButton(),
                  child: Text(
                    _pickedTime == null
                        ? "Pick Time"
                        : _pickedTime!.format(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ===================== FILE UPLOAD =====================
          ElevatedButton.icon(
            onPressed: _uploadFile,
            icon: const Icon(Icons.attach_file),
            label: const Text("Attach File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            ),
          ),

          const SizedBox(height: 20),

          // ===================== SAVE BUTTON =====================
          ElevatedButton(
            onPressed: _saveReminder,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            child: const Text("Save Reminder"),
          ),
        ],
      ),
    );
  }

  InputDecoration _bubbleInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kTextMain.withOpacity(0.45)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccentColor, width: 2),
      ),
    );
  }

  InputDecoration _bubbleFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kTextSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccentColor, width: 2),
      ),
    );
  }

  ButtonStyle _matchaBubbleButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
