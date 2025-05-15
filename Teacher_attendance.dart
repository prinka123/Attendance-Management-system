import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({super.key});

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  File? _capturedImage;
  String _responseMessage = '';

  Future<void> _captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      final directory = Directory('D:/facedetection/captures');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final savedImagePath = '${directory.path}/$formattedDate.jpg';
      final savedImage = await File(pickedFile.path).copy(savedImagePath);

      setState(() {
        _capturedImage = savedImage;
      });

      await _sendToFlask(savedImage);
    }
  }

  Future<void> _sendToFlask(File imageFile) async {
    try {
      final uri = Uri.parse("http://192.168.100.15:5000/api/mark_attendance");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseMessage = "Present Students: ${data['present'].join(", ")}";
        });
      } else {
        setState(() {
          _responseMessage = "Flask error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error sending to Flask: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Attendance"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Attendance"),
              onPressed: _captureImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            _capturedImage != null
                ? Column(
              children: [
                const Text("Images Preview:"),
                const SizedBox(height: 10),
                Image.file(_capturedImage!, height: 250),
              ],
            )
                : const Text("No image captured yet."),
            const SizedBox(height: 20),
            Text(_responseMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
