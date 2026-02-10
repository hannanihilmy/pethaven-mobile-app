import 'package:flutter/material.dart';
import 'package:pethaven/colors.dart';

class TermsAndPolicyScreen extends StatelessWidget {
  const TermsAndPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        title: const Text(
          "Terms & Privacy Policy",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌸 Cute Matcha–Strawberry Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECE7E1), // soft strawberry cream
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.pets, size: 30, color: Color(0xFF4A5F3F)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Welcome to PetHaven 🍵🍓\nPlease read our Terms & Privacy Policy.",
                      style: TextStyle(
                        color: Color(0xFF4A5F3F),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Section 1
            sectionTitle("1. Data We Collect"),
            const SizedBox(height: 6),
            bullet("Email address"),
            bullet("Pet information"),
            bullet("Reminders & activities"),
            bullet("Pet photos you upload"),

            const SizedBox(height: 20),
            strawberryDivider(),

            // Section 2
            const SizedBox(height: 20),
            sectionTitle("2. Purpose of Data Collection"),
            const SizedBox(height: 6),
            bullet("Account authentication"),
            bullet("Displaying your pets in the app"),
            bullet("Personalized reminders & schedules"),
            bullet("App improvements & feature optimization"),

            const SizedBox(height: 20),
            strawberryDivider(),

            // Section 3
            const SizedBox(height: 20),
            sectionTitle("3. Data Security"),
            const SizedBox(height: 6),
            bullet("Passwords are securely hashed (Firebase Auth)"),
            bullet("Firestore rules prevent unauthorized data access"),
            bullet("All communication uses HTTPS encryption"),

            const SizedBox(height: 20),
            strawberryDivider(),

            // Section 4
            const SizedBox(height: 20),
            sectionTitle("4. User Responsibilities"),
            const SizedBox(height: 6),
            bullet("Provide accurate information"),
            bullet("Avoid any misuse or attempts to hack the app"),
            bullet("Keep your login credentials confidential"),

            const SizedBox(height: 20),
            strawberryDivider(),

            // Section 5
            const SizedBox(height: 20),
            sectionTitle("5. Permissions Used"),
            const SizedBox(height: 6),
            bullet("Notifications for reminders"),
            bullet("Media/Storage (optional) for pet photos"),

            const SizedBox(height: 20),
            strawberryDivider(),

            // Section 6
            const SizedBox(height: 20),
            sectionTitle("6. Legal Compliance"),
            const SizedBox(height: 6),
            const Text(
              "This app follows cybersecurity best practices and PDPA principles.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF4A5F3F),
              ),
            ),

            const SizedBox(height: 25),

            // Final note
            const Text(
              "By using PetHaven, you agree to all terms listed above.",
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5F3F),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🌿 Matcha Section Title Style
  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        color: Color(0xFF4A5F3F),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // 🌱 Bullet List Style
  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF4A5F3F)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF4A5F3F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🍓 Strawberry Divider
  Widget strawberryDivider() {
    return Container(
      height: 2,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD97A8B), // strawberry shade
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
