import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Save user details to SharedPreferences
  Future<void> _saveUserToLocalStorage(String userId, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('name', name);
  }

  // Get user ID from SharedPreferences
  Future<String?> getUserFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Logout user and remove from SharedPreferences
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('name');
  }

  // 🔹 Sign Up with Email & Password
  Future<String?> signUpWithEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // Store in Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
      });

      // Save to SharedPreferences
      await _saveUserToLocalStorage(userId, name);

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // 🔹 Login with Email & Password
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      String name = userDoc['name'];

      // Save to SharedPreferences
      await _saveUserToLocalStorage(userId, name);

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // 🔹 Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Google sign-in canceled";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      String userId = userCredential.user!.uid;

      // Check if user exists in Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      String name = googleUser.displayName ?? "User";
      String email = googleUser.email;

      if (!userDoc.exists) {
        // If new user, store in Firestore
        await _firestore.collection('users').doc(userId).set({
          'name': name,
          'email': email,
        });
      }

      // Save to SharedPreferences
      await _saveUserToLocalStorage(userId, name);

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
}
