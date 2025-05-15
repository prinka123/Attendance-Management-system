import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class FaceCapture extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String role;

  FaceCapture({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  _FaceCaptureState createState() => _FaceCaptureState();
}

class _FaceCaptureState extends State<FaceCapture> {
  final ImagePicker _picker = ImagePicker();
  List<File?> capturedImages = [null, null, null, null];
  final List<String> angleLabels = ['Front', 'Left', 'Right', 'Up'];

  Future<void> _captureImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90, preferredCameraDevice: CameraDevice.front,);
    if (image == null) return;

    final InputImage inputImage = InputImage.fromFilePath(image.path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    if (faces.isNotEmpty) {
      setState(() {
        capturedImages[index] = File(image.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No face detected. Try again.')),
      );
    }
  }

  void _deleteImage(int index) {
    setState(() {
      capturedImages[index] = null;
    });
  }

  Future<void> _saveData() async {
    try {
      List<http.MultipartFile> imageFiles = [];

      for (int i = 0; i < capturedImages.length; i++) {
        if (capturedImages[i] != null) {
          final file = await http.MultipartFile.fromPath('file$i', capturedImages[i]!.path);
          imageFiles.add(file);
        }
      }

      final uri = Uri.parse('http://192.168.100.15:5000/api/register_user');
      final request = http.MultipartRequest('POST', uri)
        ..fields['name'] = widget.name
        ..fields['email'] = widget.email
        ..fields['password'] = widget.password
        ..fields['role'] = widget.role.toLowerCase()
        ..files.addAll(imageFiles);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' Registration completed!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Flask API error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5F0FA),
      appBar: AppBar(
        title: Text('Capture Face'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Capture 4 Face Angles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Text(angleLabels[index],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: capturedImages[index] != null
                                ? Image.file(capturedImages[index]!, fit: BoxFit.cover)
                                : Center(child: Text('No Image')),
                          ),
                          if (capturedImages[index] != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteImage(index),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => _captureImage(index),
                        child: Text('Capture ${angleLabels[index]}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          minimumSize: Size(100, 30),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: capturedImages.every((img) => img != null) ? _saveData : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text("Save Registration", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
