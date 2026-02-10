import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pethaven/colors.dart';

// new packages
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityScreen extends StatefulWidget {
  final String petId;
  const ActivityScreen({super.key, required this.petId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  final List<String> activityTypes = [
    "Walking",
    "Playing",
    "Training",
  ];

  String? selectedType;
  int duration = 10;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ---------------- ICON SELECTOR ----------------
  IconData _getActivityIcon(String type) {
    switch (type) {
      case "Walking":
        return Icons.directions_walk_rounded;
      case "Playing":
        return Icons.sports_tennis_rounded;
      case "Training":
        return Icons.school_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  // ---------------- ADD ACTIVITY ----------------
  Future<void> _addActivity() async {
    if (selectedType == null || _user == null) return;

    await _firestore.collection("activities").add({
      "userId": _user!.uid,
      "petId": widget.petId,
      "type": selectedType,
      "duration": duration,
      "date": DateFormat("yyyy-MM-dd").format(DateTime.now()),
      "timestamp": FieldValue.serverTimestamp(),
    });

    // play confetti on main screen
    _confettiController.play();

    if (mounted) Navigator.pop(context);
  }

  // ---------------- MODAL TO ADD ACTIVITY ----------------
  void _showAddActivityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      "Add Activity ✨",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
// ACTIVITY TYPE
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "Select Activity",
                      labelStyle: const TextStyle(color: kTextSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: "Walking",
                        child: Text("🚶 Walking"),
                      ),
                      DropdownMenuItem(
                        value: "Playing",
                        child: Text("🎾 Playing"),
                      ),
                      DropdownMenuItem(
                        value: "Training",
                        child: Text("🐕 Training"),
                      ),
                    ],
                    onChanged: (value) {
                      setModal(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 18),

                  // DURATION SLIDER
                  const Text(
                    "Duration (minutes)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$duration min",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextMain,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: kPrimaryColor,
                    onChanged: (v) => setModal(() => duration = v.toInt()),
                  ),
                  const SizedBox(height: 15),

                  // SAVE BUTTON
                  ElevatedButton(
                    onPressed: _addActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text("Save Activity"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in.")),
      );
    }
    return Stack(
      children: [
        // main UI
        Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            elevation: 0,
            title: const Text(
              "Activity Tracker 🐾",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityAnalyticsScreen(
                        petId: widget.petId,
                        userId: _user!.uid,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: kAccentColor,
            onPressed: _showAddActivityModal,
            child: const Icon(Icons.add, size: 28),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("activities")
                  .where("userId", isEqualTo: _user!.uid)
                  .where("petId", isEqualTo: widget.petId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.pets, size: 70, color: kPrimaryColor),
                        SizedBox(height: 12),
                        Text(
                          "No activities yet.\nTap + to add one!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // CALCULATE TOTAL MINUTES
                final totalMinutes = docs.fold<int>(
                  0,
                  (sum, d) => sum + ((d["duration"] ?? 0) as num).toInt(),
                );

                // STREAK CALCULATION (7-day)
                final now = DateTime.now();
                int streak = 0;
                final last7Days = <DateTime>[];

                for (int i = 6; i >= 0; i--) {
                  last7Days.add(
                    DateTime(now.year, now.month, now.day).subtract(
                      Duration(days: i),
                    ),
                  );
                }

                // for easy checking, use stored "date" field (yyyy-MM-dd)
                final activityDates =
                    docs.map((d) => (d["date"] ?? "") as String).toSet();

                // streak from today backwards
                for (int i = 0; i < 7; i++) {
                  final checkDay = DateFormat("yyyy-MM-dd").format(
                      DateTime(now.year, now.month, now.day)
                          .subtract(Duration(days: i)));

                  if (activityDates.contains(checkDay)) {
                    streak++;
                  } else {
                    break;
                  }
                }
                return Column(
                  children: [
                    // SUMMARY + STREAK CARD
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timeline,
                                  color: kPrimaryColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Weekly Summary",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: kTextMain,
                                    ),
                                  ),
                                  Text(
                                    "$totalMinutes minutes total",
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
// STREAK ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "🔥 ${streak}-day streak",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kAccentColor,
                                ),
                              ),
                              Row(
                                children: last7Days.map((day) {
                                  final key =
                                      DateFormat("yyyy-MM-dd").format(day);
                                  final hasActivity =
                                      activityDates.contains(key);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: hasActivity
                                          ? kPrimaryColor
                                          : kPrimaryColor.withOpacity(0.2),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ACTIVITY LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final ts = data["timestamp"];
                          final date = ts != null
                              ? DateFormat("MMM d").format(ts.toDate())
                              : "—";
                          return Dismissible(
                            key: Key(docs[index].id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: kErrorColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 30),
                            ),
                            onDismissed: (_) {
                              _firestore
                                  .collection("activities")
                                  .doc(docs[index].id)
                                  .delete();
                            },
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 450),
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 20),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      kPrimaryColor.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryColor.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getActivityIcon(data["type"] ?? ""),
                                        size: 28,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data["type"] ?? "",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: kTextMain,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${data["duration"] ?? 0} minutes",
                                            style: const TextStyle(
                                              color: kTextSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // CONFETTI OVERLAY
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              kAccentColor,
              kPrimaryColor,
              Colors.white,
            ],
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            maxBlastForce: 20,
            minBlastForce: 8,
          ),
        ),
      ],
    );
  }
}

// ---------------- ANALYTICS PAGE ----------------

class ActivityAnalyticsScreen extends StatelessWidget {
  final String petId;
  final String userId;

  const ActivityAnalyticsScreen({
    super.key,
    required this.petId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          "Activity Analytics 📊",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection("activities")
              .where("userId", isEqualTo: userId)
              .where("petId", isEqualTo: petId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No data yet to show charts.\nAdd some activities first 🐾",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSecondary, fontSize: 16),
                ),
              );
            }

            int walk = 0, play = 0, train = 0;
            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final type = data["type"] ?? "";
              final dur = ((data["duration"] ?? 0) as num).toInt();
              if (type == "Walking") {
                walk += dur;
              } else if (type == "Playing") {
                play += dur;
              } else if (type == "Training") {
                train += dur;
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Minutes by Activity Type",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextMain,
                  ),
                ),
                const SizedBox(height: 16),

                // BAR CHART
                SizedBox(
                  height: 260,
                  child: Card(
                    color: kCardBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  String text = "";
                                  switch (value.toInt()) {
                                    case 0:
                                      text = "Walk";
                                      break;
                                    case 1:
                                      text = "Play";
                                      break;
                                    case 2:
                                      text = "Train";
                                      break;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: walk.toDouble(),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  color: kPrimaryColor,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: play.toDouble(),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  color: kAccentColor,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: train.toDouble(),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFF42A5F5), // blue
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Quick Insights 💡",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextMain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "• Walking: $walk minutes\n"
                  "• Playing: $play minutes\n"
                  "• Training: $train minutes",
                  style: const TextStyle(
                    fontSize: 15,
                    color: kTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
