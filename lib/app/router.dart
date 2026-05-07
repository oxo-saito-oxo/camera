import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/camera_screen.dart';

class AppRoutes {
  static const camera = '/';
  static const editor = '/editor';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.camera,

  routes: [
    GoRoute(
      path: AppRoutes.camera,
      builder: (context, state) => const CameraScreen(),
    ),

    GoRoute(
      path: AppRoutes.editor,
      builder: (context, state) => const _PlaceholderScreen(title: '編集画面'),
    ),
  ],
);

// 仮の画面（人Aのコードができたら差し替える）
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — 準備中')),
    );
  }
}
