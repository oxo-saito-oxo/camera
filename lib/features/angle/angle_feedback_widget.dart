import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'angle_provider.dart';

// カメラプレビューに重ねる「枠」ウィジェット
// アングルが一致したら緑、ズレていたら白に変わる
// ConsumerWidget = Riverpod の ref.watch が使える Widget
class AngleFeedbackWidget extends ConsumerWidget {
  const AngleFeedbackWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // angleProvider の最新値を監視する
    // AsyncValue<AngleState> が返ってくる
    final angleAsync = ref.watch(angleProvider);

    // whenOrNull でデータがある時だけ色を切り替える
    // データがない（ローディング・エラー）時は白をデフォルトにする
    final isAligned =
        angleAsync.whenOrNull(data: (state) => state.isAligned) ?? false;

    // 枠の色：一致 → 緑、ズレ → 半透明の白
    final borderColor = isAligned
        ? Colors.greenAccent
        : Colors.white.withOpacity(0.5);

    // AnimatedContainer：色の変化をなめらかにアニメーションさせる
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // アニメーション時間
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 3),
      ),
    );
  }
}
