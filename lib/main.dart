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