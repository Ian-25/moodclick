import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodapp/Burgerbuttonfunc/appoint.status.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedCounselor = '';
  String reason = '';
  List<String> counselors = [];
  String? guidanceUid; // Add this line for counselor UID
  bool isAMSelected = true; // Add this line to track AM/PM selection

  @override
  void initState() {
    super.initState();
    fetchCounselors();
  }

  Future<void> fetchCounselors() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('guidance_account').get();

    setState(() {
      counselors = snapshot.docs
          .map((doc) => doc.get('displayName').toString())
          .toList();
    });
  }

  Future<Map<String, dynamic>?> _getGuidanceDetails(String displayName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('guidance_account')
          .where('displayName', isEqualTo: displayName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = snapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        guidanceUid = doc.id; // Store the counselor's UID
        return {
          'uid': doc.id,
          'email': data['email'],
          'displayName': displayName,
          'guidanceUid': doc.id,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching guidance details: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Add this method to check if time is within allowed range
  bool _isTimeAllowed(TimeOfDay time) {
    if (isAMSelected) {
      return time.hour >= 8 && time.hour < 12;
    } else {
      return time.hour >= 13 && time.hour <= 17;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final bool? amPmChoice = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Time Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Morning (8:00 AM - 11:59 AM)'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                title: const Text('Afternoon (1:00 PM - 5:00 PM)'),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        );
      },
    );

    if (amPmChoice != null) {
      setState(() {
        isAMSelected = amPmChoice;
      });

      // Show custom time picker dialog with fixed height
      final TimeOfDay? picked = await showDialog<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
                isAMSelected ? 'Select Morning Time' : 'Select Afternoon Time'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                minHeight: 200,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int index = 0; index < (isAMSelected ? 4 : 5); index++)
                      ..._buildTimeSlots(index, context),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (picked != null) {
        setState(() {
          selectedTime = picked;
        });
      }
    }
  }

  List<Widget> _buildTimeSlots(int index, BuildContext context) {
    final hour = isAMSelected ? (8 + index) : (13 + index);
    final List<TimeOfDay> timeSlots = [
      TimeOfDay(hour: hour, minute: 0),
      TimeOfDay(hour: hour, minute: 30),
    ];

    return timeSlots
        .map((time) => ListTile(
              title: Text(time.format(context)),
              onTap: () => Navigator.pop(context, time),
            ))
        .toList();
  }

  // Add this method to check for existing appointments
  Future<bool> _isTimeSlotAvailable(
      String counselorUid, DateTime date, String time) async {
    try {
      // Convert time string to DateTime for comparison
      final DateTime appointmentDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(time.split(':')[0]),
        int.parse(time.split(':')[1].split(' ')[0]),
      );

      // Query for existing appointments
      QuerySnapshot existingAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('guidanceUid', isEqualTo: counselorUid)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      return existingAppointments.docs.isEmpty;
    } catch (e) {
      print('Error checking time slot availability: $e');
      return false;
    }
  }

  Future<void> _submitAppointment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Get guidance counselor details
        final guidanceDetails = await _getGuidanceDetails(selectedCounselor);
        if (guidanceDetails == null || guidanceUid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: Could not find counselor details')),
          );
          return;
        }

        // Check if time slot is available
        bool isAvailable = await _isTimeSlotAvailable(
          guidanceUid!,
          selectedDate,
          selectedTime.format(context),
        );

        if (!isAvailable) {
          if (!mounted) return;

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Time Slot Not Available'),
                content: const Text(
                  'This counselor already has an appointment scheduled for this time. '
                  'Please select a different date or time.',
                ),
                actions: [
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
          return;
        }

        // Get user details
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Simplified appointment data structure
        final appointmentData = {
          'userId': user.uid,
          'userEmail': user.email,
          'nickname': userDoc.get('nickname') ?? '',
          'studentNumber': userDoc.get('studentNumber') ?? '',
          'guidanceUid': guidanceUid,
          'counselorName': selectedCounselor,
          'counselorEmail': guidanceDetails['email'],
          'date': Timestamp.fromDate(selectedDate),
          'time': '${selectedTime.format(context)}',
          'reason': reason,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        };

        // Create appointment
        final appointmentRef = await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);

        // Simplified notifications
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientUid': guidanceUid,
          'type': 'new_appointment',
          'appointmentId': appointmentRef.id,
          'message': 'New appointment request from ${userDoc.get('nickname')}',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentStatus()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
        backgroundColor: const Color.fromARGB(255, 243, 33, 33),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Select Counselor'),
                items: counselors.map((String counselor) {
                  return DropdownMenuItem(
                    value: counselor,
                    child: Text(counselor),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCounselor = value!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a counselor' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(
                    'Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(
                  'Time: ${selectedTime.format(context)} (${isAMSelected ? "Morning" : "Afternoon"})',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Reason for Appointment'),
                maxLines: 3,
                onChanged: (value) => reason = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Schedule Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
