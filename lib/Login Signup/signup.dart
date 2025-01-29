import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moodapp/Services/auth_service.dart';
import 'package:flutter/services.dart'; // Add this import

class RegisterScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneNumbweController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Hello! Register to get started",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(nicknameController, "NickName"),
                const SizedBox(height: 10),
                _buildAgeField(),
                const SizedBox(height: 20),
                _buildGenderDropdown(), // Add this line
                const SizedBox(height: 20),
                _buildTextField(phoneNumbweController, "phoneNumber"),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                _buildTextField(studentNumberController, "Student Number"),
                const SizedBox(height: 10),
                _buildDepartmentField(),
                const SizedBox(height: 10),
                _buildTextField(emailController, "Email"),
                const SizedBox(height: 10),
                _buildTextField(passwordController, "Password",
                    obscureText: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _registerUser(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF586EFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Register",
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
        ),
      ),
    );
  }

  // Register User and Save to Firestore
  Future<void> _registerUser(BuildContext context) async {
    try {
      // Authenticate user with Firebase
      UserCredential userCredential = (await AuthService().signup(
        email: emailController.text,
        password: passwordController.text,
        context: context,
      )) as UserCredential;

      // Save additional user details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'nickname': nicknameController.text,
        'gender': genderController.text,
        'age': ageController.text,
        'phoneNumber': phoneNumbweController.text,
        'studentNumber': studentNumberController.text,
        'department': departmentController.text,
        'email': emailController.text,
        'uid': userCredential.user?.uid,
        'created_at': Timestamp.now(),
      });

      Fluttertoast.showToast(
        msg: "Registration successful!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Navigate to home or login screen after registration
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: ": $e",
      );
    }
  }

  // Text Field for User Input
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  // Age Field (Validates Age)
  Widget _buildAgeField() {
    return TextFormField(
      controller: ageController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ], // Add this line
      decoration: InputDecoration(
        labelText: "Age",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your age';
        }
        final age = int.tryParse(value);
        if (age == null || age < 0) {
          return 'Please enter a valid age';
        }
        return null;
      },
    );
  }

  // Dropdown for Department Selection
  Widget _buildDepartmentField() {
    return DropdownButtonFormField<String>(
      value: null,
      onChanged: (value) {
        departmentController.text = value ?? '';
      },
      items: const [
        DropdownMenuItem(value: 'ITE', child: Text('ITE')),
        DropdownMenuItem(value: 'CICS', child: Text('CICS')),
      ],
      decoration: InputDecoration(
        labelText: "Select Department",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your department';
        }
        return null;
      },
    );
  }

  // Dropdown for Gender Selection
  Widget _buildGenderDropdown() {
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
            genderController.text = value!;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
}
