import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

// スマホのカメラ一覧を入れる変数
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('カメラの取得エラー: ${e.code}, ${e.description}');
  }
  runApp(const ProviderScope(child: MyApp()));
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
  // === Week 1: カメラ用の変数 ===
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  XFile? _capturedImage;

  // === Week 2: オーバーレイ用の変数 ===
  XFile? _guideImage; // アルバムから選んだお手本画像
  double _overlayOpacity = 0.5; // 画像の透明度（初期値は50%）
  bool _isOverlayVisible = false; // ガイド画像を表示するかどうかのスイッチ
  final ImagePicker _picker = ImagePicker(); // アルバムを開くためのパッケージ

  @override
  void initState() {
    super.initState();
    _setupPermissionsAndCamera();
  }

  // 権限を聞いてからカメラを起動する関数
  Future<void> _setupPermissionsAndCamera() async {
    await [Permission.camera, Permission.photos].request();
    await _initCamera(_selectedCameraIndex);
  }

  // カメラの初期設定関数
  Future<void> _initCamera(int cameraIndex) async {
    if (cameras.isEmpty || cameraIndex < 0 || cameraIndex >= cameras.length)
      return;

    final oldController = _controller;
    final newController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false, // 録音しない（エラー回避）
    );

    _controller = newController;
    _initializeControllerFuture = newController.initialize();

    await _initializeControllerFuture;
    await oldController?.dispose();

    if (mounted) {
      setState(() {});
    }
  }

  // === Week 2: ギャラリーから画像を選ぶ関数 ===
  Future<void> _pickGuideImage() async {
    try {
      // アルバムを開いて画像を選択
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _guideImage = image;
          _isOverlayVisible = true; // 画像を選んだら自動で表示をONにする
        });
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
    }
  }

  // カメラ切り替え関数
  void _switchCamera() {
    if (cameras.length < 2) return;
    final nextIndex = _selectedCameraIndex == 0 ? 1 : 0;
    setState(() {
      _selectedCameraIndex = nextIndex;
    });
    _initCamera(nextIndex);
  }

  // シャッターを切る関数
  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final image = await controller.takePicture();
      if (!mounted) return;

      setState(() {
        _capturedImage = image;
      });

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

    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;

    if (controller == null ||
        initializeFuture == null ||
        !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 【1番奥】カメラの映像
          Positioned.fill(child: CameraPreview(controller)),

          // 【2番目】Week 2: ガイド画像を重ねる
          if (_isOverlayVisible && _guideImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: _overlayOpacity, // スライダーの数値で透明度が変わる
                child: IgnorePointer(
                  // 画像が邪魔でボタンが押せなくなるのを防ぐ
                  child: Image.file(
                    File(_guideImage!.path),
                    fit: BoxFit.cover, // 画面いっぱいに広げる
                  ),
                ),
              ),
            ),

          // 【3番目 (上部)】Week 2: 操作UI（写真選択・表示トグル・スライダー）
          Positioned(
            top: 60, // 画面上部の余白
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 左上：アルバムを開くボタン
                    IconButton(
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _pickGuideImage,
                    ),
                    // 右上：表示・非表示のトグルボタン（画像がある時だけ出す）
                    if (_guideImage != null)
                      IconButton(
                        icon: Icon(
                          _isOverlayVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isOverlayVisible = !_isOverlayVisible;
                          });
                        },
                      ),
                  ],
                ),
                // スライダー（画像が表示されている時だけ出す）
                if (_isOverlayVisible && _guideImage != null)
                  Slider(
                    value: _overlayOpacity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.amber, // スライダーの色
                    onChanged: (value) {
                      setState(() {
                        _overlayOpacity = value;
                      });
                    },
                  ),
              ],
            ),
          ),

          // 【4番目 (下部)】Week 1: カメラ操作ボタン
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
