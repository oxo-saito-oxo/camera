import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// 端末で利用可能なカメラのリスト
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Flutterの初期化処理
  WidgetsFlutterBinding.ensureInitialized();
  
  // スマホに付いているカメラを取得
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('カメラの取得エラー: ${e.code}, ${e.description}');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Guide App',
      theme: ThemeData.dark(),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // 最初のカメラ（通常は背面カメラ）を初期化
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      _initializeControllerFuture = _controller.initialize();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Scaffold(body: Center(child: Text('カメラが見つかりません')));
    }

    return Scaffold(
      // 1. カメラプレビューを画面いっぱいに表示
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox.expand(
              child: CameraPreview(_controller),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  
  // ★追加: 現在選択されているカメラのインデックス（0:背面, 1:前面）
  int _selectedCameraIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex); // ★変更: 関数に分けた
  }

  // ★追加: カメラを初期設定する関数
  void _initCamera(int cameraIndex) {
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[cameraIndex], ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  // ★追加: 前面・背面カメラを切り替える関数
  void _switchCamera() {
    if (cameras.length < 2) return;
    setState(() {
      _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
      _initCamera(_selectedCameraIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Scaffold(body: Center(child: Text('カメラが見つかりません')));
    }

    return Scaffold(
      // ★変更: Stackを使って映像の上にボタンを重ねる
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          
          // ★追加: 画面右下に切り替えボタンを配置
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
        ],
      ),
    );
  }
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0; 
  
  // ★追加: 撮影した画像データを保持する変数
  XFile? _capturedImage;

  // ... (initState, _initCamera, _switchCamera, dispose はそのまま) ...

  // ★追加: シャッターを切る関数
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      
      setState(() {
        _capturedImage = image; // 変数に画像を保存
      });
      
      debugPrint("📸 撮影成功: ${image.path}");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('撮影しました！')),
        );
      }
    } catch (e) {
      debugPrint("撮影エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Scaffold(body: Center(child: Text('カメラが見つかりません')));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          
          // 右下の切り替えボタン
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

          // ★追加: 中央下のシャッターボタン
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton(
                heroTag: 'shutter_btn',
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}