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

  // Add new method to check user approval status
  Future<bool> checkUserApprovalStatus(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.exists &&
          (userDoc.data() as Map<String, dynamic>)['isApproved'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<UserCredential?> signup({
    required String email,
    required String password,
    required BuildContext context,
    required Map<String, dynamic> userData, // Add this parameter
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details with approval status and all user data
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'nickname': userData['nickname'] ?? '',
        'gender': userData['gender'] ?? '',
        'age': userData['age'] ?? '',
        'phoneNumber': userData['phoneNumber'] ?? '',
        'department': userData['department'] ?? '',
        'studentNumber': userData['studentNumber'] ?? '',
        'isApproved': false,
        'isDeclined': false,
        'registeredAt': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending',
        'uid': userCredential.user!.uid,
      });

      // Show registration success message
      Fluttertoast.showToast(
        msg: "Registration successful! Please wait for admin approval.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Sign out the user until approved
      await _auth.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const LoginScreen(),
        ),
      );

      return userCredential;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Registration failed: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<UserCredential?> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication failed.',
        );
      }

      // Get user document from Firestore
      final userDoc =
          await _firestore.collection('users').doc(authResult.user!.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User account not found.',
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if account is deactivated
      if (userData['isDeactivated'] == true || userData['isActive'] == false) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'account-deactivated',
          message: 'Your account has been deactivated. Please contact admin.',
        );
      }

      // Check existing approval status
      if (userData['isDeclined'] == true) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'account-declined',
          message: 'Your account has been declined by the admin.',
        );
      }

      if (userData['isApproved'] != true) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'not-approved',
          message: 'Your account is pending admin approval.',
        );
      }

      // Update last login time without using FieldValue
      await _firestore.collection('users').doc(authResult.user!.uid).update({
        'lastLoginAt': DateTime.now().toUtc().toIso8601String(),
      });

      // Navigate to home screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const HomeScreen(),
          ),
        );
      }

      return authResult;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-deactivated':
          message = 'Your account has been deactivated. Please contact admin.';
          break;
        case 'not-approved':
          message = 'Your account is pending wait for admin approval.';
          break;
        case 'account-declined':
          message = 'Your account has been declined by the admin.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Invalid password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'null-user':
          message = 'Authentication failed. Please try again.';
          break;
        default:
          message = 'Login failed: ${e.message ?? 'Unknown error'}';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> signout({required BuildContext context}) async {
    await _auth.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const LoginScreen()),
    );
  }

  Future<void> saveUserDetails(Map<String, dynamic> userDetails) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Sanitize the data before saving
        Map<String, dynamic> sanitizedDetails = {};
        userDetails.forEach((key, value) {
          if (value != null) {
            sanitizedDetails[key] = value.toString();
          }
        });

        // Always use string for timestamp
        sanitizedDetails['lastLoginAt'] =
            DateTime.now().toUtc().toIso8601String();

        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(sanitizedDetails);
      }
    } catch (e) {
      print('Error saving user details: $e');
    }
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'nickname': data['nickname']?.toString() ?? '',
            'gender': data['gender']?.toString() ?? '',
            'age': data['age']?.toString() ?? '',
            'phoneNumber': data['phoneNumber']?.toString() ?? '',
            'department': data['department']?.toString() ?? '',
            'email': data['email']?.toString() ?? '',
            'studentNumber': data['studentNumber']?.toString() ?? '',
            'isApproved': data['isApproved'] ?? false,
            'isDeclined': data['isDeclined'] ?? false,
          };
        }
      }
      return {};
    } catch (e) {
      print('Error getting user details: $e');
      return {};
    }
  }

  Future<bool> checkAccountStatus(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['isActive'] == true &&
          userData['isDeactivated'] != true &&
          userData['isApproved'] == true;
    } catch (e) {
      print('Error checking account status: $e');
      return false;
    }
  }

  // Add method for admin to deactivate account
  Future<void> deactivateUserAccount(String uid, String reason) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': false,
        'isDeactivated': true,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivationReason': reason,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      // Force sign out if user is currently logged in
      User? currentUser = _auth.currentUser;
      if (currentUser?.uid == uid) {
        await _auth.signOut();
      }
    } catch (e) {
      print('Error deactivating account: $e');
      throw e;
    }
  }

  // Add method for admin to reactivate account
  Future<void> reactivateUserAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': true,
        'isDeactivated': false,
        'deactivatedAt': null,
        'deactivationReason': null,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reactivating account: $e');
      throw e;
    }
  }
}
