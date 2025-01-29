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
  Widget build(BuildContext context) {
    return const MaterialApp(
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

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  void _loadUserNickname() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        nickname = userDoc['nickname'] ?? "User";
      });
    }
  }

  void setMood(String newMood) {
    setState(() {
      mood = newMood;
    });
  }

  void _updateMoodInFirestore(String newMood) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference moodUpdateRef =
          await FirebaseFirestore.instance.collection('moodupdate').add({
        'nickname': nickname,
        'mood': newMood,
        'timestamp': Timestamp.now(),
      });

      // Update the admin_dashboard collection
      await FirebaseFirestore.instance
          .collection('admin_dashboard')
          .doc(moodUpdateRef.id)
          .set({
        'nickname': nickname,
        'mood': newMood,
        'timestamp': Timestamp.now(),
      });
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
        moodText = "I’m Feeling Sad";
        moodColor = Colors.orange;
        break;
      case "Disappointed":
        backgroundColor = Colors.brown.shade300;
        emoji = "😟"; // Disappointed emoji
        moodText = "I’m Feeling Disappointed";
        moodColor = Colors.brown;
        break;
      case "Scared":
        backgroundColor = Colors.blueAccent;
        emoji = "😨"; // Scared emoji
        moodText = "I’m Feeling Scared";
        moodColor = Colors.blue;
        break;
      case "Angry":
        backgroundColor = Colors.redAccent;
        emoji = "😡"; // Angry emoji
        moodText = "I’m Feeling Angry";
        moodColor = Colors.red;
        break;
      case "Happy":
      default:
        backgroundColor = const Color.fromARGB(235, 246, 255, 0);
        emoji = "😊"; // Happy emoji
        moodText = "I’m Feeling Happy";
        moodColor = Colors.yellow;
        break;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                fontSize: 24,
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
              onPressed: () {
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
              },
              buttonText: "Mood Update",
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoodHistoryScreen(),
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
              child: const Text(
                "View Mood History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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

// Add this function to check mood updates count
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

    return moodUpdates.docs.length < 2;
  }
  return false;
}
