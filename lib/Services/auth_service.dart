import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moodapp/Home/home.dart';
import 'package:moodapp/Login Signup/login.dart';
import 'package:moodapp/Success/successregister.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'nickname': '',
        'gender': '',
        'age': '',
        'phoneNumber': '',
        'department': '',
      });

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const RegistrationSuccessPage(),
        ),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    return null;
  }

  Future<UserCredential?> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Auto-save nickname when user logs in
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      String nickname = doc.get('nickname') ?? '';
      if (nickname.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'nickname': nickname,
        });
      }

      // Save user details to profile page
      await saveUserDetails({
        'nickname': doc.get('nickname') ?? '',
        'gender': doc.get('gender') ?? '',
        'age': doc.get('age') ?? '',
        'phoneNumber': doc.get('phoneNumber') ?? '',
        'department': doc.get('department') ?? '',
        'email': doc.get('email') ?? '',
      });

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const HomeScreen(),
        ),
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'invalid-email' || e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    return null;
  }

  Future<void> signout({required BuildContext context}) async {
    await _auth.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const LoginScreen()),
    );
  }

  Future<Map<String, String>> getUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return {
        'nickname': doc.get('nickname') ?? '',
        'gender': doc.get('gender') ?? '',
        'age': doc.get('age') ?? '',
        'phoneNumber': doc.get('phoneNumber') ?? '',
        'department': doc.get('department') ?? '',
        'email': doc.get('email') ?? '',
      };
    }
    return {};
  }

  Future<void> saveUserDetails(Map<String, String> userDetails) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update(userDetails);
    }
  }
}
