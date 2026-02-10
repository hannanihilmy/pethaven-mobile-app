import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    forceCodeForRefreshToken: true, // ✅ ensures account chooser reappears
  );

  // 🔐 Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // ✅ Always sign out first to clear any cached Google session
      await _googleSignIn.signOut();

      // 🔁 Prompt the user to pick an account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // user canceled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ✅ sign in with Firebase using the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  // 🚪 Sign out completely (Google + Firebase)
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
