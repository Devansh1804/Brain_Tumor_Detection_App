import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

// ... (imports remain unchanged)

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({Key? key}) : super(key: key);

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  File? _image;
  String _result = "";
  double _confidence = 0.0;
  Interpreter? _interpreter;
  bool _isInterpreterInitialized = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tumor_model.tflite');
      setState(() {
        _isInterpreterInitialized = true;
      });
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);
    setState(() {
      _image = imageFile;
      _result = "";
      _confidence = 0.0;
    });
  }

  Float32List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r / 255.0;
        convertedBytes[pixelIndex++] = pixel.g / 255.0;
        convertedBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes;
  }

  Future<void> detectTumor() async {
    if (!_isInterpreterInitialized || _image == null) return;

    try {
      final bytes = await _image!.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        setState(() => _result = "Invalid image");
        return;
      }

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      int inputSize = inputShape[1];
      final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);
      final input = imageToByteListFloat32(resizedImage, inputSize).reshape([1, inputSize, inputSize, 3]);

      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape([1, outputShape[1]]);
      _interpreter!.run(input, output);

      final conf = output[0][0];
      setState(() {
        _confidence = conf;
        _result = conf > 0.5 ? "🧠 Tumor Detected" : "✅ No Tumor Detected";
      });
    } catch (e) {
      setState(() => _result = "Detection error: $e");
    }
  }

  Widget buildConfidenceIndicator(double confidence) {
    int percent = (confidence * 100).round();
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: DonutPainter(confidence),
              ),
              Text(
                "$percent%",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDetectEnabled = _isInterpreterInitialized && _image != null;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/brain.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "🧠 Brain Tumor Detection",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 2),
                          blurRadius: 4,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: _image == null
                                    ? Image.asset('assets/images/placeholder.png', height: 200)
                                    : Image.file(_image!, height: 200),
                              ),
                              const SizedBox(height: 25),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: MaterialButton(
                                  onPressed: pickImage,
                                  child: const Text(
                                    "📁 Upload MRI Image",
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: isDetectEnabled
                                      ? const LinearGradient(
                                    colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                                  )
                                      : const LinearGradient(
                                    colors: [Colors.grey, Colors.grey],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: MaterialButton(
                                  onPressed: isDetectEnabled ? detectTumor : null,
                                  child: const Text(
                                    "🔍 Detect Tumor",
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (_confidence > 0) buildConfidenceIndicator(_confidence),
                              const SizedBox(height: 20),
                              if (_result.isNotEmpty)
                                Text(
                                  _result,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _result.contains("No") ? Colors.green : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              const SizedBox(height: 50), // space for back button
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Back"),
                          ),
                        ),
                      ],
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
}

// DonutPainter remains unchanged
class DonutPainter extends CustomPainter {
  final double confidence;
  DonutPainter(this.confidence);

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 12;
    Rect rect = Offset.zero & size;

    Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade300;

    Paint foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: [Colors.pink, Colors.pink],
        stops: [confidence, confidence],
      ).createShader(rect);

    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - strokeWidth / 2, background);
    canvas.drawArc(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      -pi / 2,
      2 * pi * confidence,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.confidence != confidence;
  }
}

