import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'registration_screen.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RegistrationScreen(),
      routes: {
        '/login': (context) =>  Login(),
      },
    );
  }
}

