import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moodapp/Services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void _loadProfileData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            nicknameController.text = userData['nickname'] ?? '';
            genderController.text = userData['gender'] ?? '';
            ageController.text = userData['age']?.toString() ?? '';
            studentNumberController.text = userData['studentNumber'] ?? '';
            phoneNumberController.text = userData['phoneNumber'] ?? '';
            departmentController.text = userData['department'] ?? '';
            emailController.text = userData['email'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      Fluttertoast.showToast(
        msg: 'Error loading profile data',
        backgroundColor: Colors.red,
      );
    }
  }

  void _saveProfileData() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'nickname': nicknameController.text,
            'gender': genderController.text,
            'age': ageController.text,
            'phoneNumber': phoneNumberController.text,
            'department': departmentController.text,
          });

          Fluttertoast.showToast(
            msg: 'Profile updated successfully!',
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        print('Error updating profile: $e');
        Fluttertoast.showToast(
          msg: 'Error updating profile',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _updatePassword() async {
    String currentPassword = currentPasswordController.text;
    String newPassword = newPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      _showToast("Please fill out both fields");
    } else if (newPassword.length < 6) {
      _showToast("Password must be at least 6 characters");
    } else {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);

        _showToast("Password updated successfully");
        currentPasswordController.clear();
        newPasswordController.clear();
      } catch (e) {
        _showToast("Failed to update password. Please try again.");
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Click'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile info'),
            Tab(text: 'Security'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileInfoTab(),
          _buildSecurityTab(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restore original simple CircleAvatar
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              nicknameController.text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField('Nickname', nicknameController),
                const SizedBox(height: 10),
                buildGenderDropdown(), // Add this line
                const SizedBox(height: 10),
                buildTextField('Age', ageController),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: studentNumberController,
                      readOnly: true, // Make student number read-only
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Student Number',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                buildTextField('phoneNumber', phoneNumberController),
                const SizedBox(height: 10),
                buildDepartmentDropdown(), // Add this line
                const SizedBox(height: 10),
                buildTextField('Email address', emailController),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF586EFF),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Save edit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Change password",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Current password",
              filled: true,
              fillColor: Colors.grey[200],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "New password",
              filled: true,
              fillColor: Colors.grey[200],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF586EFF),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _updatePassword,
              child: const Text(
                "Update password",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: label == 'Email address', // Make email read-only
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: genderController.text.isEmpty ? null : genderController.text,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
          ],
          onChanged: (value) {
            setState(() {
              genderController.text = value!;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your gender';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: departmentController.text.isEmpty
              ? null
              : departmentController.text,
          items: const [
            DropdownMenuItem(value: 'ITE', child: Text('ITE')),
            DropdownMenuItem(value: 'CICS', child: Text('CICS')),
          ],
          onChanged: (value) {
            setState(() {
              departmentController.text = value!;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your department';
            }
            return null;
          },
        ),
      ],
    );
  }
}
