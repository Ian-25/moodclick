import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodapp/Home/menu.dart';
import 'package:moodapp/Services/auth_service.dart';
import 'package:moodapp/Home/notifi.dart'; // Import the notification function
import 'package:keyboard_actions/keyboard_actions.dart'; // Add this import

void main() {
  runApp(const MoodClickApp());
}

class MoodClickApp extends StatelessWidget {
  const MoodClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // Initial screen
      routes: {
        '/menu': (context) => const AppDrawer(), // Route to menu page
        '/notification': (context) =>
            const NotificationPage(), // Route to notification page
        '/profile': (context) => const ProfileInfoScreen(), // Route to profile page
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeWall'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.pushNamed(context, '/menu'); // Navigate to menu page
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(
                  context, '/notifi'); // Navigate to notification page
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.blue),
            onPressed: () {
              Navigator.pushNamed(
                  context, '/profile'); // Navigate to profile page
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: MoodList(),
      ),
    );
  }
}

class MoodList extends StatefulWidget {
  const MoodList({super.key});

  @override
  _MoodListState createState() => _MoodListState();
}

class _MoodListState extends State<MoodList> {
  final TextEditingController _moodController = TextEditingController();
  final CollectionReference _moodsCollection =
      FirebaseFirestore.instance.collection('moods');
  String nickname = '';
  String selectedMood = '😊';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  void _loadNickname() async {
    var userDetails = await AuthService().getUserDetails();
    setState(() {
      nickname = userDetails['nickname'] ?? '';
    });
  }

  void _postMood() async {
    if (_moodController.text.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _moodsCollection.add({
          'nickname': nickname, // Use the user's nickname
          'mood': selectedMood, // Use the selected mood emoji
          'dateTime': DateTime.now().toString(),
          'description': _moodController.text,
          'cares': 0,
        });
        _moodController.clear();
      }
    }
  }

  void _showPostComposer({MoodCardData? moodData}) {
    if (moodData != null) {
      _moodController.text = moodData.description;
      selectedMood = moodData.mood;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this line
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Add this line
          ),
          child: KeyboardActions(
            config: _buildConfig(context), // Add this line
            child: SingleChildScrollView(
              // Wrap with SingleChildScrollView
              padding: const EdgeInsets.all(30.0),
              child: Align(
                // Add Align widget
                alignment: Alignment.center, // Center the content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMood,
                      items: const [
                        DropdownMenuItem(value: '😊', child: Text('😊 Happy')),
                        DropdownMenuItem(value: '😢', child: Text('😢 Sad')),
                        DropdownMenuItem(
                            value: '😞', child: Text('😞 Disappointed')),
                        DropdownMenuItem(value: '😱', child: Text('😱 Scared')),
                        DropdownMenuItem(value: '😡', child: Text('😡 Angry')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedMood = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Mood',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                      ),
                    ),
                    // Add this line
                    const SizedBox(height: 10),
                    TextField(
                      controller: _moodController,
                      decoration: InputDecoration(
                        hintText: 'How do you feel today?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                      ),
                      // Add this line to make the input text box wider
                      minLines: 15,
                      maxLines: null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (moodData == null) {
                          _postMood();
                        } else {
                          _updateMood(moodData);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      actions: [
        KeyboardActionsItem(
          focusNode: FocusNode(),
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Done"),
                ),
              );
            },
          ],
        ),
      ],
    );
  }

  void _updateMood(MoodCardData moodData) async {
    if (_moodController.text.isNotEmpty) {
      await _moodsCollection.doc(moodData.id).update({
        'description': _moodController.text,
        'mood': selectedMood,
      });
      _moodController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showPostComposer(),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 20.0), // Adjusted padding
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  // Wrap Text with Expanded
                  child: Text(
                    'How do you feel today?',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _moodsCollection
                .orderBy('dateTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final moods = snapshot.data!.docs
                  .map((doc) => MoodCardData.fromDocument(doc))
                  .toList();
              return ListView.builder(
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  return MoodCard(moods[index],
                      onEdit: () => _showPostComposer(moodData: moods[index]));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class MoodCardData {
  final String nickname;
  final String mood;
  final String dateTime;
  final String description;
  int cares;
  final String id;

  MoodCardData(this.nickname, this.mood, this.dateTime, this.description,
      this.cares, this.id);

  factory MoodCardData.fromDocument(DocumentSnapshot doc) {
    return MoodCardData(
      doc['nickname'],
      doc['mood'],
      doc['dateTime'],
      doc['description'],
      doc['cares'],
      doc.id,
    );
  }
}

class MoodCard extends StatefulWidget {
  final MoodCardData data;
  final VoidCallback onEdit;

  const MoodCard(this.data, {required this.onEdit, super.key});

  @override
  _MoodCardState createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  bool _hasReacted = false;

  @override
  void initState() {
    super.initState();
    _checkUserReaction();
  }

  void _checkUserReaction() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('moods')
          .doc(widget.data.id)
          .collection('reactions')
          .doc(user.uid)
          .get();
      if (mounted) {
        // Add this check
        setState(() {
          _hasReacted = doc.exists;
        });
      }
    }
  }

  void _toggleReaction() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference reactionRef = FirebaseFirestore.instance
          .collection('moods')
          .doc(widget.data.id)
          .collection('reactions')
          .doc(user.uid);

      if (_hasReacted) {
        await reactionRef.delete();
        if (mounted) {
          // Add this check
          setState(() {
            widget.data.cares -= 1;
            _hasReacted = false;
          });
        }
      } else {
        await reactionRef.set({'reacted': true});
        if (mounted) {
          // Add this check
          setState(() {
            widget.data.cares += 1;
            _hasReacted = true;
          });
        }
        sendNotification(widget.data.id, widget.data.nickname,
            'reacted to your post'); // Send notification
      }

      await FirebaseFirestore.instance
          .collection('moods')
          .doc(widget.data.id)
          .update({'cares': widget.data.cares});
    }
  }

  void sendNotification(String postId, String nickname, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'postOwnerId': FirebaseAuth.instance.currentUser!.uid,
      'reactingUserId': nickname,
      'reaction': message,
      'postTitle': postId,
      'timestamp': Timestamp.now(),
    });
  }

  void _deletePost() async {
    await FirebaseFirestore.instance
        .collection('moods')
        .doc(widget.data.id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.data.nickname} - ${widget.data.mood}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(widget.data.dateTime,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(widget.data.description),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${widget.data.cares} Heart'),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleReaction,
                      icon: Icon(
                        _hasReacted ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: const Text('Heart'),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit();
                        } else if (value == 'delete') {
                          _deletePost();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: const Center(child: Text('Menu Page')),
    );
  }
}

class ProfileInfoScreen extends StatelessWidget {
  const ProfileInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}
