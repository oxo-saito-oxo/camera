import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// 端末で利用可能なカメラのリスト
List<CameraDescription> cameras = [];

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    debugPrint('=== _initCamera開始: index=$cameraIndex, cameras=${cameras.length}個 ===');
    if (cameras.isEmpty || cameraIndex < 0 || cameraIndex >= cameras.length) {
      debugPrint('カメラが見つからないため終了');
      return;
    }

    try {
      final oldController = _controller;
      final newController = CameraController(
        cameras[cameraIndex],
        ResolutionPreset.high,
      );

      debugPrint('CameraController作成完了、initialize()開始...');
      _controller = newController;
      _initializeControllerFuture = newController.initialize();

      await oldController?.dispose();
      await _initializeControllerFuture;

      debugPrint('カメラ初期化成功！');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'カメラの起動に失敗しました: $e';
        });
      }
    }
  }

  void _switchCamera() {
    if (cameras.length < 2) return;

    final nextIndex = _selectedCameraIndex == 0 ? 1 : 0;
    setState(() {
      _selectedCameraIndex = nextIndex;
    });
    _initCamera(nextIndex);
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;
    if (controller == null || initializeFuture == null) return;

    try {
      await initializeFuture;
      final image = await controller.takePicture();

      if (!mounted) return;

      debugPrint('撮影成功: ${image.path}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('撮影しました！')));
    } catch (e) {
      debugPrint('撮影エラー: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Scaffold(body: Center(child: Text('カメラが見つかりません')));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    final initializeFuture = _initializeControllerFuture;
    final controller = _controller;

    if (initializeFuture == null || controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(controller);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: FloatingActionButton(
              heroTag: 'switch_btn',
              backgroundColor: Colors.black54,
              onPressed: _switchCamera,
              child: const Icon(Icons.flip_camera_ios, color: Colors.white),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FloatingActionButton(
                heroTag: 'shutter_btn',
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
