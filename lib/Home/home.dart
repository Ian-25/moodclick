import 'dart:async';

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
        '/profile': (context) =>
            const ProfileInfoScreen(), // Route to profile page
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const BurgerButton(), // Add drawer widget
      appBar: AppBar(
        title: const Text('FreeWall'),
        leading: Builder(
          // Add this Builder widget
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final int unreadCount =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;

                  if (unreadCount == 0) return const SizedBox();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
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
  bool _isDisposed = false;
  StreamSubscription<QuerySnapshot>? _moodSubscription;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _moodSubscription?.cancel();
    _moodController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _loadNickname() async {
    if (_isDisposed) return;

    try {
      var userDetails = await AuthService().getUserDetails();
      _safeSetState(() {
        nickname = userDetails['nickname'] ?? '';
      });
    } catch (e) {
      print('Error loading nickname: $e');
    }
  }

  void _postMood() async {
    if (_isDisposed) return;

    if (_moodController.text.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          var userDetails = await AuthService().getUserDetails();
          String currentNickname = userDetails['nickname'] ?? '';

          if (currentNickname.isEmpty) {
            if (!_isDisposed && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please set your nickname in profile before posting'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          await _moodsCollection.add({
            'nickname': currentNickname,
            'mood': selectedMood,
            'dateTime': DateTime.now().toString(),
            'description': _moodController.text,
            'cares': 0,
            'userId': user.uid,
            'creatorNickname': currentNickname,
          });

          if (!_isDisposed) {
            _moodController.clear();
          }
        } catch (e) {
          print('Error posting mood: $e');
        }
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
              if (!mounted) return Container();

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final moods = snapshot.data!.docs
                  .map((doc) => MoodCardData.fromDocument(doc))
                  .toList();

              return ListView.builder(
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  if (!mounted) return Container();
                  return MoodCard(
                    moods[index],
                    onEdit: () => _showPostComposer(moodData: moods[index]),
                  );
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
  final String userId;
  final String creatorNickname; // Add creator's nickname

  MoodCardData(
    this.nickname,
    this.mood,
    this.dateTime,
    this.description,
    this.cares,
    this.id,
    this.userId,
    this.creatorNickname, // Add to constructor
  );

  factory MoodCardData.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MoodCardData(
      data['nickname'] ?? '',
      data['mood'] ?? '',
      data['dateTime'] ?? '',
      data['description'] ?? '',
      data['cares'] ?? 0,
      doc.id,
      data['userId'] ?? '',
      data['creatorNickname'] ?? '', // Get creator's nickname
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
  bool _isPostOwner = false;
  String _currentUserNickname = '';
  bool _isDisposed = false; // Add this line
  StreamSubscription? _reactionSubscription; // Add this line
  StreamSubscription? _ownershipSubscription; // Add this line

  @override
  void initState() {
    super.initState();
    _checkUserReaction();
    _checkPostOwnership();
    _loadCurrentUserNickname();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reactionSubscription?.cancel(); // Cancel subscriptions
    _ownershipSubscription?.cancel();
    super.dispose();
  }

  // Safe setState wrapper
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _loadCurrentUserNickname() async {
    if (_isDisposed) return;

    try {
      var userDetails = await AuthService().getUserDetails();
      _safeSetState(() {
        _currentUserNickname = userDetails['nickname'] ?? '';
      });
    } catch (e) {
      print('Error loading nickname: $e');
    }
  }

  void _checkUserReaction() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _reactionSubscription = FirebaseFirestore.instance
          .collection('moods')
          .doc(widget.data.id)
          .collection('reactions')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        _safeSetState(() {
          _hasReacted = doc.exists;
        });
      });
    }
  }

  void _checkPostOwnership() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _ownershipSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((userDoc) {
        _safeSetState(() {
          _isPostOwner = widget.data.userId == currentUser.uid;
        });
      });
    }
  }

  void _toggleReaction() async {
    if (_isDisposed) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // References for batch operation
        final moodRef =
            FirebaseFirestore.instance.collection('moods').doc(widget.data.id);
        final reactionRef = moodRef.collection('reactions').doc(user.uid);

        WriteBatch batch = FirebaseFirestore.instance.batch();

        if (_hasReacted) {
          // Remove reaction
          batch.delete(reactionRef);
          batch.update(moodRef, {'cares': FieldValue.increment(-1)});

          if (!_isDisposed) {
            _safeSetState(() {
              widget.data.cares -= 1;
              _hasReacted = false;
            });
          }
        } else {
          // Add reaction
          batch.set(reactionRef, {
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'userNickname': _currentUserNickname,
          });

          batch.update(moodRef, {'cares': FieldValue.increment(1)});

          // Create notification for post owner
          if (user.uid != widget.data.userId) {
            // Don't notify if reacting to own post
            DocumentReference notificationRef =
                FirebaseFirestore.instance.collection('notifications').doc();

            batch.set(notificationRef, {
              'type': 'reaction',
              'userId': widget.data.userId,
              'postId': widget.data.id,
              'reactorId': user.uid,
              'reactorName': _currentUserNickname,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'message': '$_currentUserNickname reacted to your post'
            });
          }

          if (!_isDisposed) {
            _safeSetState(() {
              widget.data.cares += 1;
              _hasReacted = true;
            });
          }
        }

        await batch.commit();
      } catch (e) {
        print('Error toggling reaction: $e');
        // Revert local state if operation failed
        if (!_isDisposed) {
          _safeSetState(() {
            widget.data.cares =
                _hasReacted ? widget.data.cares - 1 : widget.data.cares + 1;
            _hasReacted = !_hasReacted;
          });
        }
      }
    }
  }

  void sendNotification(String postId, String nickname, String message) {
    // Implement your notification logic here
    print('Notification sent: $nickname $message');
  }

  Future<void> _handleEdit() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.data.userId == currentUser.uid) {
      widget.onEdit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit posts you created'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.data.userId == currentUser.uid) {
      // Show confirmation dialog
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        await FirebaseFirestore.instance
            .collection('moods')
            .doc(widget.data.id)
            .delete();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete posts you created'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.data.nickname} - ${widget.data.mood}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final currentUser = snapshot.data!;
                      if (widget.data.userId == currentUser.uid) {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _handleEdit();
                            } else if (value == 'delete') {
                              _handleDelete();
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
                        );
                      }
                    }
                    return const SizedBox
                        .shrink(); // Return empty widget if not owner
                  },
                ),
              ],
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
                ElevatedButton.icon(
                  onPressed: _toggleReaction,
                  icon: Icon(
                    _hasReacted ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: const Text('Heart'),
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
