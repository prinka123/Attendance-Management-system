import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'face_capture.dart';
import 'login.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool showRegistrationForm = false;
  String selectedRole = 'Student';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void goBackToSelection() {
    setState(() {
      showRegistrationForm = false;
    });
  }

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'name': name,
        'role': selectedRole,
        'email': email,
        'password': password,
        'createdAt': Timestamp.now(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceCapture(
            name: name,
            email: email,
            password: password,
            role: selectedRole,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: showRegistrationForm ? BackButton(onPressed: goBackToSelection) : null,
        title: Text(showRegistrationForm ? "Create Account" : "Create Account",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: showRegistrationForm ? _buildForm() : _buildSelectionButtons(),
      ),
    );
  }

  Widget _buildSelectionButtons() {
    return Column(
      children: [
        SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                showRegistrationForm = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text("Create Account", style: TextStyle(fontSize: 16)),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.blue),
            ),
            child: Text("Login", style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtons(
          isSelected: [selectedRole == 'Student', selectedRole == 'Teacher'],
          onPressed: (index) {
            setState(() {
              selectedRole = index == 0 ? 'Student' : 'Teacher';
            });
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: Colors.blue.shade700,
          color: Colors.black,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text("Student"),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text("Teacher"),
            ),
          ],
        ),
        SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: createAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text("Next", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
