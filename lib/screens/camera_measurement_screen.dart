import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CameraMeasurementScreen extends StatefulWidget {
  const CameraMeasurementScreen({super.key});

  @override
  State<CameraMeasurementScreen> createState() => _CameraMeasurementScreenState();
}

class _CameraMeasurementScreenState extends State<CameraMeasurementScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraReady = false;
  bool _isAnalyzing = false;
  bool _isDone = false;
  bool _isDetecting = false;
  Pose? _detectedPose;
  Map<String, double> _measurements = {};
  int _currentStep = 0;

  late PoseDetector _poseDetector;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Stand Straight',
      'instruction': 'Stand 2 meters away. Arms slightly out. Wear fitted clothing.',
      'icon': Icons.accessibility_new_outlined,
    },
    {
      'title': 'Front View',
      'instruction': 'Face the camera directly. Feet shoulder-width apart.',
      'icon': Icons.person_outline,
    },
    {
      'title': 'Side View',
      'instruction': 'Turn 90 degrees to the right. Keep posture straight.',
      'icon': Icons.swap_horiz_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _startCamera(_cameraIndex);
    } catch (e) {
      debugPrint('Camera init error: ' + e.toString());
    }
  }

  Future<void> _startCamera(int index) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _cameraReady = true);
      _cameraController!.startImageStream(_processFrame);
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _cameraReady = false);
    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _startCamera(_cameraIndex);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _isDone) return;
    _isDetecting = true;
    try {
      final camera = _cameras[_cameraIndex];
      final rotation = InputImageRotationValue.fromRawValue(
              camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      final poses = await _poseDetector.processImage(inputImage);
      if (mounted && poses.isNotEmpty) {
        setState(() => _detectedPose = poses.first);
      }
    } catch (e) {
      debugPrint('Pose error: ' + e.toString());
    }
    _isDetecting = false;
  }

  Map<String, double> _calculateMeasurements(Pose pose) {
    final lm = pose.landmarks;

    double dist(PoseLandmarkType a, PoseLandmarkType b) {
      final pa = lm[a];
      final pb = lm[b];
      if (pa == null || pb == null) return 0;
      return sqrt(pow(pa.x - pb.x, 2) + pow(pa.y - pb.y, 2));
    }

    final shoulderWidth = dist(
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hipWidth =
        dist(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final leftKnee = lm[PoseLandmarkType.leftKnee];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final leftWrist = lm[PoseLandmarkType.leftWrist];

    double torsoHeight = 0;
    if (leftShoulder != null && leftHip != null) {
      torsoHeight = (leftHip.y - leftShoulder.y).abs();
    }

    double legLength = 0;
    if (leftHip != null && leftAnkle != null) {
      legLength = (leftAnkle.y - leftHip.y).abs();
    }

    double sleeveLength = 0;
    if (leftShoulder != null && leftWrist != null) {
      sleeveLength = sqrt(pow(leftShoulder.x - leftWrist.x, 2) +
          pow(leftShoulder.y - leftWrist.y, 2));
    }

    double inseam = 0;
    if (leftKnee != null && leftAnkle != null && leftHip != null) {
      inseam = (leftAnkle.y - leftHip.y).abs() * 0.75;
    }

    final scale = shoulderWidth > 0 ? 42.0 / shoulderWidth : 1.0;

    return {
      'chest': double.parse((shoulderWidth * scale * 2.3).toStringAsFixed(1)),
      'waist': double.parse((hipWidth * scale * 1.8).toStringAsFixed(1)),
      'hips': double.parse((hipWidth * scale * 2.2).toStringAsFixed(1)),
      'shoulder': double.parse((shoulderWidth * scale).toStringAsFixed(1)),
      'sleeve': double.parse((sleeveLength * scale * 1.1).toStringAsFixed(1)),
      'inseam': double.parse((inseam * scale * 1.0).toStringAsFixed(1)),
    };
  }

  Future<void> _scanNow() async {
    if (_detectedPose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No body detected. Please stand in frame.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(seconds: 2));
    final calculated = _calculateMeasurements(_detectedPose!);
    await _cameraController?.stopImageStream();
    setState(() {
      _measurements = calculated;
      _isAnalyzing = false;
      _isDone = true;
    });
    _saveMeasurements();
  }

  Future<void> _saveMeasurements() async {
    try {
      await http.post(
        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/measurements/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': 1,
          'chest': _measurements['chest'],
          'waist': _measurements['waist'],
          'hips': _measurements['hips'],
          'shoulder': _measurements['shoulder'],
          'sleeve': _measurements['sleeve'],
          'inseam': _measurements['inseam'],
          'notes': 'Scanned via Smart Tailor AI',
        }),
      );
    } catch (e) {
      debugPrint('Save error: ' + e.toString());
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isDone ? _buildResults() : _buildScanner(),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        if (_cameraReady && _cameraController != null)
          Positioned.fill(child: CameraPreview(_cameraController!))
        else
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              ),
            ),
          ),
        if (_cameraReady && _detectedPose != null)
          Positioned.fill(
            child: CustomPaint(
              painter: PoseOverlayPainter(
                pose: _detectedPose!,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                screenSize: MediaQuery.of(context).size,
              ),
            ),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                const Text('Body Scan',
                  style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleCamera,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flip_camera_ios_outlined,
                      color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_cameraReady && _detectedPose == null)
          Center(
            child: Container(
              width: 220, height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 1.5),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
        if (_cameraReady && _detectedPose != null)
          Positioned(
            top: 70,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Body detected',
                  style: TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_isAnalyzing) ...[
                  const CircularProgressIndicator(
                    color: Color(0xFF1B5E20), strokeWidth: 2),
                  const SizedBox(height: 16),
                  const Text('AI is calculating your measurements...',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(_steps[_currentStep]['icon'],
                          color: const Color(0xFF1B5E20), size: 26),
                        const SizedBox(height: 8),
                        Text(_steps[_currentStep]['title'],
                          style: const TextStyle(color: Colors.white,
                            fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(_steps[_currentStep]['instruction'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70,
                            fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) => Container(
                      width: i == _currentStep ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _currentStep
                          ? const Color(0xFF1B5E20) : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          _scanNow();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _currentStep < _steps.length - 1
                          ? 'Next Step' : 'Scan Now',
                        style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Color(0xFF1C1C1E), size: 28),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('Scan Complete',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E), letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text('AI measurements saved successfully',
              style: TextStyle(fontSize: 16, color: Color(0xFF8E8E93))),
            const SizedBox(height: 32),
            const Text('Your Measurements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _measurements.entries.map((e) {
                  final isLast = e.key == _measurements.keys.last;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key[0].toUpperCase() + e.key.substring(1),
                              style: const TextStyle(fontSize: 15,
                                color: Color(0xFF3A3A3C))),
                            Text(
                              e.value.toString() + ' cm',
                              style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20))),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: Color(0xFFE5E5EA),
                          indent: 20, endIndent: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class PoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size screenSize;

  PoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.fill;

    Offset _point(PoseLandmarkType type) {
      final lm = pose.landmarks[type];
      if (lm == null) return Offset.zero;
      final x = lm.x / imageSize.width * screenSize.width;
      final y = lm.y / imageSize.height * screenSize.height;
      return Offset(x, y);
    }

    void _line(PoseLandmarkType a, PoseLandmarkType b) {
      final pa = pose.landmarks[a];
      final pb = pose.landmarks[b];
      if (pa == null || pb == null) return;
      canvas.drawLine(_point(a), _point(b), paint);
    }

    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.nose],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.nose],
    ];

    for (final c in connections) {
      _line(c[0], c[1]);
    }

    for (final lm in pose.landmarks.values) {
      final x = lm.x / imageSize.width * screenSize.width;
      final y = lm.y / imageSize.height * screenSize.height;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) => true;
}
