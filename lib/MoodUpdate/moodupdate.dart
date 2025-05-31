import 'dart:async';

import 'package:flutter/material.dart';
// Import the necessary package for user credentials
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodapp/Home/home.dart';
// Import HomePage
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moodapp/MoodUpdate/moodhistory.dart'; // Import Fluttertoast

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MoodSelectorScreen(),
    );
  }
}

class MoodSelectorScreen extends StatefulWidget {
  const MoodSelectorScreen({super.key});

  @override
  _MoodSelectorScreenState createState() => _MoodSelectorScreenState();
}

class _MoodSelectorScreenState extends State<MoodSelectorScreen> {
  String mood = "Happy"; // Default mood
  String nickname = "User"; // Default nickname
  bool _isDisposed = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  // Safe setState wrapper
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _loadUserNickname() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use stream subscription instead of one-time get
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDoc) {
          _safeSetState(() {
            nickname = userDoc.get('nickname') ?? "User";
          });
        });
      }
    } catch (e) {
      print('Error loading nickname: $e');
    }
  }

  void setMood(String newMood) {
    _safeSetState(() {
      mood = newMood;
    });
  }

  Future<void> _updateMoodInFirestore(String newMood) async {
    if (_isDisposed) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        // Use batch write for atomic operations
        WriteBatch batch = FirebaseFirestore.instance.batch();

        DocumentReference moodRef =
            FirebaseFirestore.instance.collection('moodupdate').doc();
        DocumentReference dashboardRef = FirebaseFirestore.instance
            .collection('admin_dashboard')
            .doc(moodRef.id);

        final moodData = {
          'nickname': nickname,
          'mood': newMood,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
        };

        batch.set(moodRef, moodData);
        batch.set(dashboardRef, moodData);
        await batch.commit();

        if (!_isDisposed && mounted) {
          Fluttertoast.showToast(
            msg: "Mood Update Successfully",
            backgroundColor: Colors.green,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Error updating mood: $e');
      if (!_isDisposed && mounted) {
        Fluttertoast.showToast(
          msg: "Failed to update mood",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < 0) {
      // Swipe left
      setMood(mood == "Sad"
          ? "Disappointed"
          : mood == "Disappointed"
              ? "Scared"
              : mood == "Scared"
                  ? "Angry"
                  : mood == "Angry"
                      ? "Happy"
                      : "Sad");
    } else if (details.primaryVelocity! > 0) {
      // Swipe right
      setMood(mood == "Happy"
          ? "Sad"
          : mood == "Sad"
              ? "Disappointed"
              : mood == "Disappointed"
                  ? "Scared"
                  : mood == "Scared"
                      ? "Angry"
                      : "Happy");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String emoji;
    String moodText;
    Color moodColor;

    // Define mood characteristics based on the selected mood
    switch (mood) {
      case "Sad":
        backgroundColor = Colors.orangeAccent;
        emoji = "😞"; // Sad emoji
        moodText = "I'm Feeling Sad";
        moodColor = Colors.orange;
        break;
      case "Disappointed":
        backgroundColor = Colors.brown.shade300;
        emoji = "😟"; // Disappointed emoji
        moodText = "I'm Feeling Disappointed";
        moodColor = Colors.brown;
        break;
      case "Scared":
        backgroundColor = Colors.blueAccent;
        emoji = "😨"; // Scared emoji
        moodText = "I'm Feeling Scared";
        moodColor = Colors.blue;
        break;
      case "Angry":
        backgroundColor = Colors.redAccent;
        emoji = "😡"; // Angry emoji
        moodText = "I'm Feeling Angry";
        moodColor = Colors.red;
        break;
      case "Happy":
      default:
        backgroundColor = const Color.fromARGB(235, 246, 255, 0);
        emoji = "😊"; // Happy emoji
        moodText = "I'm Feeling Happy";
        moodColor = Colors.yellow;
        break;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Text(
          "Hey $nickname!",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "How are you feeling this day?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              moodText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            MoodSelectorButton(
              moodColor: moodColor,
              onPressed: () async {
                // Check if user can update mood
                bool canUpdate = await _canUpdateMood();
                if (canUpdate) {
                  Fluttertoast.showToast(
                    msg: "Mood Update Successfully",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                  _updateMoodInFirestore(mood); // Update mood in Firestore
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const HomeScreen()), // Navigate to HomePage
                  );
                } else {
                  _showLimitWarning(context);
                }
              },
              buttonText: "Mood Update",
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoodHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: moodColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                elevation: 5,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text(
                    "View Mood History",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            MoodSelectorBar(moodColor: moodColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setMood(mood == "Happy"
                        ? "Sad"
                        : mood == "Sad"
                            ? "Disappointed"
                            : mood == "Disappointed"
                                ? "Scared"
                                : mood == "Scared"
                                    ? "Angry"
                                    : "Happy");
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () {
                    setMood(mood == "Sad"
                        ? "Disappointed"
                        : mood == "Disappointed"
                            ? "Scared"
                            : mood == "Scared"
                                ? "Angry"
                                : mood == "Angry"
                                    ? "Happy"
                                    : "Sad");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MoodSelectorButton extends StatelessWidget {
  final Color moodColor;
  final VoidCallback onPressed;
  final String buttonText;

  const MoodSelectorButton({
    super.key,
    required this.moodColor,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: moodColor,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        elevation: 5,
      ),
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: moodColor,
        ),
      ),
    );
  }
}

class MoodSelectorBar extends StatelessWidget {
  final Color moodColor;

  const MoodSelectorBar({super.key, required this.moodColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: moodColor,
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 8,
          backgroundColor: moodColor.withOpacity(0.6),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 8,
          backgroundColor: moodColor.withOpacity(0.3),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 8,
          backgroundColor: moodColor.withOpacity(0.1),
        ),
      ],
    );
  }
}

// Add this function to check mood updates count for today
Future<bool> _canUpdateMood() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Get today's start and end timestamps
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // Query mood updates for today
    QuerySnapshot moodUpdates = await FirebaseFirestore.instance
        .collection('moodupdate')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Check if user has less than 3 updates today
    return moodUpdates.docs.length < 3;
  }
  return false;
}

// Add this function to show warning message
void _showLimitWarning(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: const Text(
            'You can only update your mood 3 times per day. Please try again tomorrow.'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
