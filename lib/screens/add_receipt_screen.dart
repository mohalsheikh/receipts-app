import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AddReceiptScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onCaptured;
  const AddReceiptScreen({
    super.key,
    required this.onBack,
    required this.onCaptured,
  });

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  bool _isReady = false;
  String? _error;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (s == AppLifecycleState.inactive) {
      _ctrl?.dispose();
      setState(() => _isReady = false);
    } else if (s == AppLifecycleState.resumed)
      _initCam();
  }

  Future<void> _initCam() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw 'No cameras found (Simulator?)';

      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      _ctrl = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _ctrl!.initialize();
      if (!mounted) return;

      try {
        await _ctrl!.setFlashMode(FlashMode.off);
      } catch (_) {}

      setState(() {
        _isReady = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera Error: $e');
    }
  }

  Future<void> _snap() async {
    if (!_isReady || _ctrl!.value.isTakingPicture) return;
    try {
      await HapticFeedback.mediumImpact();
      final f = await _ctrl!.takePicture();
      widget.onCaptured(f.path);
    } catch (e) {
      debugPrint("Snap error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onBack,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _ctrl == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_ctrl!),
          CustomPaint(painter: _OverlayPainter()),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: widget.onBack,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align receipt',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _flash == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        try {
                          final n = _flash == FlashMode.off
                              ? FlashMode.torch
                              : FlashMode.off;
                          _ctrl!.setFlashMode(n);
                          setState(() => _flash = n);
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(32, 30, 32, 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      final x = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (x != null) widget.onCaptured(x.path);
                    },
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  GestureDetector(
                    onTap: _snap,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: s.width * 0.85,
      height: s.height * 0.65,
    );
    c.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & s),
        Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(12))),
      ),
      Paint()..color = Colors.black45,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(12)),
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
