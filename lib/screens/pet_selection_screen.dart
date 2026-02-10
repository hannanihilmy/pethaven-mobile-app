import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pethaven/screens/home_screen.dart';
import 'package:pethaven/screens/pet_profile_screen.dart';
import 'package:pethaven/colors.dart';

class PetSelectionScreen extends StatefulWidget {
  const PetSelectionScreen({super.key});

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Select Your Pet 🐾",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('pets')
            .where('userId', isEqualTo: userId)
            // IMPORTANT: remove orderBy for now to avoid crashes
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyPet(context);
          }

          final pets = snapshot.data!.docs;

          // ⭐️ SAFE SORTING (supports pets without timestamp)
          pets.sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['timestamp'];
            final tb = (b.data() as Map<String, dynamic>)['timestamp'];

            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index].data() as Map<String, dynamic>;
                final petId = pets[index].id;

                final name = pet['name'] ?? 'Unnamed';
                final species = pet['species']?.toString().toLowerCase() ?? "";

                final defaultImage = species == 'cat'
                    ? 'assets/images/cat.png'
                    : 'assets/images/dog.png';

                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(petId: petId),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCardBackground,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: pet['imageUrl'] != null &&
                                  pet['imageUrl'].toString().isNotEmpty
                              ? Image.network(
                                  pet['imageUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Image.asset(
                                      defaultImage,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  defaultImage,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species == "cat" ? "Cat" : "Dog",
                          style: const TextStyle(
                            color: kTextMain,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PetProfileScreen(selectedPetId: ''), // Add new pet
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pet'),
        backgroundColor: kAccentColor,
      ),
    );
  }

  Widget _emptyPet(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/nopetadded.png', height: 140),
          const SizedBox(height: 20),
          const Text(
            "No pets added yet 🐶🐱",
            style: TextStyle(fontSize: 18, color: kTextMain),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PetProfileScreen(selectedPetId: ''),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Your First Pet"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }
}
