import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

// アングル状態をまとめたデータクラス
class AngleState {
  final double roll;
  final double pitch;
  final bool isAligned;

  const AngleState({
    required this.roll,
    required this.pitch,
    required this.isAligned,
  });
}

// 加速度センサーを監視する StreamProvider
// センサーのデータが来るたびに自動で更新される
final angleProvider = StreamProvider<AngleState>((ref) {
  return accelerometerEventStream().map((event) {
    final roll = atan2(event.x, event.z) * 180 / pi; // 左右の傾き
    final pitch = atan2(event.y, event.z) * 180 / pi; // 前後の傾き
    const threshold = 5.0;
    final isAligned = roll.abs() < threshold && pitch.abs() < threshold;
    return AngleState(roll: roll, pitch: pitch, isAligned: isAligned);
  });
});
