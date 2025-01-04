import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:summarify/Utilities/theme_provider.dart';
import 'package:provider/provider.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save results method
  Future<void> saveResults(List<Map<String, dynamic>> summarizeContent) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      for (var result in summarizeContent) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('summarizeContent')
            .add({
          ...result,
          'timestamp': FieldValue.serverTimestamp(), // Add timestamp
        });
      }
    } catch (e) {
      print('Error saving results to Firebase: $e');
      throw e;
    }
  }

  // Retrieve historical results method
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('summarizeContent')
          .orderBy('timestamp', descending: true)
          .get();

      // Print document IDs for debugging
      for (var doc in querySnapshot.docs) {
        print('Document ID: ${doc.id}');
      }

      // Include document ID in the results
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp =
            data['timestamp']?.toDate(); // Convert timestamp to DateTime
        return {
          'documentId': doc.id, // Add documentId to each result
          'timestamp': timestamp,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error retrieving results from Firebase: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> searchHistory(String query) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

      // Convert query to lowercase for case-insensitive search
      final lowerCaseQuery = query.toLowerCase();

      // Query the subcollection 'results'
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('summarizeContent')
          .get();

      final summarizeContent = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Filter results on the client side for array fields and other fields
      return summarizeContent.where((doc) {
        final title = (doc['title'] as String? ?? '').toLowerCase();
        final summary = (doc['summary'] as String? ?? '').toLowerCase();
        final briefQuestions = List<String>.from(doc['brief_questions'] ?? [])
            .map((q) => q.toLowerCase())
            .toList();
        final mcqQuestions = List<String>.from(doc['mcq_questions'] ?? [])
            .map((q) => q.toLowerCase())
            .toList();

        // Check if the query matches filename, summary, or any question in the arrays
        return title.contains(lowerCaseQuery) ||
            summary.contains(lowerCaseQuery) ||
            briefQuestions.any((q) => q.contains(lowerCaseQuery)) ||
            mcqQuestions.any((q) => q.contains(lowerCaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching history: $e');
      throw e;
    }
  }

  Future<void> deleteResult(String documentId) async {
    try {
      if (documentId.isEmpty) {
        throw ArgumentError('Document ID cannot be empty');
      }

      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('summarizeContent')
          .doc(documentId)
          .delete();
      print('Document deleted successfully');
    } catch (e) {
      print('Error deleting result: $e');
      throw e;
    }
  }

  Future<void> logUserActivity(String activity) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      await FirebaseFirestore.instance.collection('user_activities').add({
        'activity': activity,
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': userId, // Use the actual user ID here
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;
      print("Signed in with Google: ${user?.email}");

      // Get user's display name
      String? userName = user?.displayName ?? 'No name available';
      print("User Name: $userName");

      // Log sign-in activity
      logUserActivity('Signed in with Google');

      // Handle post-sign-in logic (e.g., navigate to home page or dashboard)
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
       // Reset the theme to light mode
      Provider.of<ThemeProvider>(context, listen: false).setLightMode();
      // Optionally, log sign-out activity
      await logUserActivity('Signed out');
      await _auth.signOut();
      await _googleSignIn.signOut();

      // Handle post-sign-out logic (e.g., navigate to login page)
    } catch (e) {
      print("Error: $e");
    }
  }
}
