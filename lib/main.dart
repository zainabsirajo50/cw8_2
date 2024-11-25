import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';  // Import google_ml_kit

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ImageLabelingApp());
}

class ImageLabelingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageLabelingScreen(),
    );
  }
}

class ImageLabelingScreen extends StatefulWidget {
  @override
  _ImageLabelingScreenState createState() => _ImageLabelingScreenState();
}

class _ImageLabelingScreenState extends State<ImageLabelingScreen> {
  File? _image;
  final _picker = ImagePicker();
  List<String> _labels = [];

  // Pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _labelImage();
    }
  }

  Future<void> _labelImage() async {
    try {
      if (_image == null) {
        print("No image selected.");
        return;
      }

      // Initialize ImageLabeler from google_ml_kit
      final labeler = GoogleMlKit.vision.imageLabeler();
      final inputImage = InputImage.fromFilePath(_image!.path);

      // Get image labels
      final labels = await labeler.processImage(inputImage);

      if (labels.isNotEmpty) {
        setState(() {
          _labels = labels
              .map((label) {
                double confidence = label.confidence ?? 0.0;
                return "${label.label}: ${confidence.toStringAsFixed(2)}%";
              })
              .toList();
        });
      } else {
        setState(() {
          _labels = ["No labels detected."];
        });
      }
    } catch (e) {
      print("Error labeling image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Labeling"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text("Take Photo"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text("Select from Gallery"),
            ),
            SizedBox(height: 20),
            _image != null
                ? Image.file(
                    _image!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : Text("No image selected"),
            SizedBox(height: 20),
            _labels.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _labels.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_labels[index]),
                        );
                      },
                    ),
                  )
                : Text("No labels detected."),
          ],
        ),
      ),
    );
  }
}