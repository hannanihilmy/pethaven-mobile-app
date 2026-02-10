import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pethaven/screens/login_screen.dart';
import 'package:pethaven/screens/pet_selection_screen.dart';
import 'package:pethaven/colors.dart';
import 'terms_and_policy_screen.dart'; // ⭐ Add this import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;

  // ⭐ New fields for T&C
  bool _agreedToPolicy = false;

  // ⭐ Strong password checker
  bool get isPasswordStrong {
    String p = _passwordCtrl.text;

    bool hasUpper = p.contains(RegExp(r'[A-Z]'));
    bool hasNumber = p.contains(RegExp(r'[0-9]'));
    bool hasSymbol = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    bool enoughLength = p.length >= 8;

    return hasUpper && hasNumber && hasSymbol && enoughLength;
  }

  // REGISTER FUNCTION
  Future<void> _register() async {
    String email = _emailCtrl.text.trim();
    String pass = _passwordCtrl.text.trim();
    String confirm = _confirmCtrl.text.trim();

// EMPTY CHECK
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    // EMAIL FORMAT VALIDATION
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email format.")),
      );
      return;
    }

    // TERMS CHECK
    if (!_agreedToPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the Terms & Conditions")),
      );
      return;
    }

    // STRONG PASSWORD CHECK
    if (!isPasswordStrong) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Password must be 8+ chars, include uppercase, number & symbol."),
        ),
      );
      return;
    }

    // MATCH CHECK
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    // START LOADING
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PetSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String error = "Registration failed.";

      if (e.code == "weak-password") {
        error = "The password provided is too weak.";
      } else if (e.code == "email-already-in-use") {
        error = "This email is already registered.";
      } else if (e.code == "invalid-email") {
        error = "The email address is invalid.";
      } else if (e.code == "network-request-failed") {
        error = "Please check your internet connection.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.png', width: 130, height: 130),
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kAccentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text(
                  'Create your account 🐾',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sign up to start your PetHaven journey!',
                  style: TextStyle(color: kTextMain, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // EMAIL
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kTextMain),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: kTextSecondary),
                    prefixIcon: const Icon(Icons.email, color: kAccentColor),
                    filled: true,
                    fillColor: kCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(color: kTextMain),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: kTextSecondary),
                    prefixIcon: const Icon(Icons.lock, color: kAccentColor),
                    filled: true,
                    fillColor: kCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // ⭐ Password strength hint
                const SizedBox(height: 6),
                Text(
                  isPasswordStrong
                      ? "Strong password ✔"
                      : "Must contain: Uppercase, Number, Symbol & 8+ chars",
                  style: TextStyle(
                    color: isPasswordStrong ? Colors.green : Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(color: kTextMain),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: kTextSecondary),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: kAccentColor),
                    filled: true,
                    fillColor: kCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🌸 Cute Matcha–Strawberry T&C Section
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFF3EEE8), // soft strawberry cream background
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(0xFFD97A8B), // 🍓 strawberry outline
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToPolicy,
                        onChanged: (v) => setState(() => _agreedToPolicy = v!),
                        activeColor: const Color(0xFFD97A8B), // strawberry
                        side: const BorderSide(
                          color: Color(0xFF4A5F3F), // matcha border
                          width: 1.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsAndPolicyScreen(),
                              ),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.eco, // 🌿 small matcha leaf icon
                                  size: 18,
                                  color: Color(0xFF4A5F3F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  "I agree to the Terms & Conditions and Privacy Policy",
                                  style: TextStyle(
                                    color: Color(0xFF4A5F3F), // matcha text
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    height: 1.4,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SIGN UP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: kTextMain, fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Log In!',
                        style: TextStyle(
                          color: kAccentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Center(
                  child: Icon(Icons.pets, color: kAccentColor, size: 48),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
