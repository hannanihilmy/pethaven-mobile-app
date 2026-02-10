import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pethaven/screens/reminders_screen.dart';
import 'package:pethaven/screens/pet_profile_screen.dart';
import 'package:pethaven/screens/pet_selection_screen.dart';
import 'package:pethaven/screens/login_screen.dart';
import 'package:pethaven/screens/activity_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:pethaven/colors.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final String petId;
  const HomeScreen({super.key, required this.petId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? petData;
  List<dynamic> articles = [];
  int _selectedIndex = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ▼ Initialize PageView controller
    _carouselController = PageController(viewportFraction: 0.88);

    // ▼ Load articles from assets
    _loadArticles();

    // ▼ Load pet data
    _loadPetData();

    // ▼ Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();

    // ▼ Auto-slide Carousel every 4s
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_carouselController.hasClients && articles.isNotEmpty) {
        int next = (_currentCarouselIndex + 1) % articles.length;

        _carouselController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPetData() async {
    if (_user == null) return;
    final snap = await _firestore.collection('pets').doc(widget.petId).get();
    if (snap.exists) {
      setState(() => petData = snap.data());
    }
  }

  Future<void> _loadArticles() async {
    final jsonStr = await rootBundle.loadString('assets/advice.json');
    setState(() => articles = json.decode(jsonStr));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _fadeController.reset();
      _selectedIndex = index;
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      ReminderScreen(selectedPetId: widget.petId),
      const PetSelectionScreen(),
      PetProfileScreen(selectedPetId: widget.petId),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: const Text(
          'PetHaven 🏡',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          backgroundColor: kPrimaryColor,
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home_filled, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              activeIcon: Icon(Icons.alarm_on, size: 28),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              activeIcon: Icon(Icons.pets, size: 28),
              label: 'Switch Pet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  } // HOME PAGE

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: _loadPetData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (petData != null) _buildPetCard(petData!) else _loadingCard(),
            const SizedBox(height: 25),
            _buildActivitySummary(),
            const SizedBox(height: 25),
            const Text(
              'Upcoming Reminders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildUpcomingReminders(),
            const SizedBox(height: 25),
            Row(
              children: const [
                Icon(Icons.lightbulb, color: Color(0xFF4A5F3F), size: 26),
                SizedBox(width: 8),
                Text(
                  "Pet Care Tips",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A5F3F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Daily tips to keep your pet happy, healthy, and loved 🐾",
              style: TextStyle(fontSize: 14.5, color: kTextSecondary),
            ),
            const SizedBox(height: 10),
            _buildArticleCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: kAccentColor),
        ),
      );

  // PET CARD
  Widget _buildPetCard(Map<String, dynamic> data) {
    final name = data['name'];
    final species = data['species'];
    final breed = data['breed'];
    final weight = data['weight'];
    final weightUnit = data['weightUnit'];
    final imageUrl = data['imageUrl'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kAccentColor.withOpacity(0.3),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: kPrimaryColor.withOpacity(0.5), width: 3),
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                backgroundColor: kAccentColor.withOpacity(0.4),
                child: imageUrl == null
                    ? const Icon(Icons.pets, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? "Pet",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kTextMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$species • $breed",
                    style: const TextStyle(
                      fontSize: 15,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$weight $weightUnit",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODAY'S ACTIVITY
  Widget _buildActivitySummary() {
    if (_user == null) return const SizedBox();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Activity",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A5F3F),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityScreen(petId: widget.petId),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: kAccentColor,
                  ),
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("activities")
                  .where("userId", isEqualTo: _user!.uid)
                  .where("petId", isEqualTo: widget.petId)
                  .where("date", isEqualTo: todayStr)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snap.data!.docs.isEmpty) {
                  return const Text(
                    "No activities logged today.\nTap 'View All' to add one! 🐾",
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                    ),
                  );
                }

                final docs = snap.data!.docs;
                final walk = _sumActivity(docs, "Walking");
                final play = _sumActivity(docs, "Playing");
                final train = _sumActivity(docs, "Training");

                return Column(
                  children: [
                    _cuteActivityRow("Walking 🐾", walk, Icons.directions_walk),
                    _cuteActivityRow("Playing 🎾", play, Icons.sports_tennis),
                    _cuteActivityRow("Training 🦮", train, Icons.school),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuteActivityRow(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextMain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$value min",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kTextMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _sumActivity(List<QueryDocumentSnapshot> docs, String type) {
    num total = 0;
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data["type"] == type) {
        total += (data["duration"] ?? 0);
      }
    }
    return total.toInt();
  } // UPCOMING REMINDERS

  // UPCOMING REMINDERS (MODIFIED)
  Widget _buildUpcomingReminders() {
    if (_user == null) {
      return const Text("Login to view reminders.");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reminders')
          .where('userId', isEqualTo: _user!.uid)
          .where('petId', isEqualTo: widget.petId)
          .orderBy('datetime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();

        // ⭐️ FILTER → Only upcoming reminders
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dt = DateTime.tryParse(data['datetime'] ?? '');
          return dt != null && dt.isAfter(now);
        }).toList();

        if (docs.isEmpty) {
          return const Text(
            "No upcoming reminders.",
            style: TextStyle(color: kTextSecondary),
          );
        }

        // ⭐️ SORT BY SOONEST
        docs.sort((a, b) {
          final ad = DateTime.parse((a.data() as Map)['datetime']);
          final bd = DateTime.parse((b.data() as Map)['datetime']);
          return ad.compareTo(bd);
        });

        // ⭐️ SHOW ONLY FIRST 3
        final limited = docs.take(3).toList();

        // ⭐️ NEXT REMINDER COUNTDOWN
        final nextData = limited.first.data() as Map<String, dynamic>;
        final nextDate = DateTime.parse(nextData['datetime']);
        final diff = nextDate.difference(now);

        String formatCountdown(Duration d) {
          if (d.inDays >= 1) return "${d.inDays}d ${d.inHours % 24}h";
          if (d.inHours >= 1) return "${d.inHours}h ${d.inMinutes % 60}m";
          return "${d.inMinutes} min";
        }

        final countdown = formatCountdown(diff);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐️ COUNTDOWN TIMER DISPLAY
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "⏳ Next reminder in: $countdown",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextMain,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ⭐️ REMINDER CARDS (FIRST 3 ONLY)
            Column(
              children: limited.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'];
                final type = data['type'];
                final date = DateTime.parse(data['datetime']);
                final formatted =
                    DateFormat('MMM d, yyyy • hh:mm a').format(date);

                // ⭐️ TYPE BADGE COLOR
                Color tagColor = kPrimaryColor;
                if (type == "Feeding") tagColor = const Color(0xFF8BC34A);
                if (type == "Medication") tagColor = const Color(0xFFF06292);
                if (type == "Vet Appointment")
                  tagColor = const Color(0xFF42A5F5);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tagColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.alarm, color: tagColor),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextMain,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐️ TYPE BADGE
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: tagColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          formatted,
                          style: const TextStyle(color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // PET CARE TIPS CAROUSEL
  Widget _buildArticleCarousel() {
    if (articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _carouselController,
            padEnds: false,
            itemCount: articles.length,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemBuilder: (context, index) {
              final article = articles[index];

              return AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: _currentCarouselIndex == index ? 1.0 : 0.92,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _currentCarouselIndex == index ? 1.0 : 0.6,
                  child: _buildCarouselCard(article),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            articles.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentCarouselIndex == i ? 22 : 8,
              decoration: BoxDecoration(
                color: _currentCarouselIndex == i
                    ? kAccentColor
                    : kPrimaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> article) {
    final image = article['image'];
    final title = article['title'];
    final category = article['category'] ?? "Pet Care";

    return GestureDetector(
      onTap: () => _openArticleDialog(article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: kCardBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Stack(
              children: [
                // IMAGE
                Image.asset(
                  image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Category tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Title
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kTextMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ARTICLE POP-UP
  void _openArticleDialog(Map<String, dynamic> article) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (article['image'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(article['image']),
                ),
              const SizedBox(height: 15),
              Text(
                article['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4A5F3F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                article['body'],
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
