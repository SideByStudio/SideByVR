import '../l10n/app_language.dart';
import 'package:flutter/material.dart';

/// VR 查看器居中信息面板：三行（查看状态 / i·n / 操作提示）。
/// 左右半屏各渲染一份（由调用方用 Row+Expanded 复制）。
class ViewerInfoPanel extends StatelessWidget {
  final double zoom;
  final double ipdOffset;
  final int index; // 1-based
  final int total;
  final ViewerInfoMode mode;

  const ViewerInfoPanel({
    super.key,
    required this.zoom,
    required this.ipdOffset,
    required this.index,
    required this.total,
    this.mode = ViewerInfoMode.image,
  });

  @override
  Widget build(BuildContext context) {
    final mediaLabel = switch (mode) {
      ViewerInfoMode.image => '',
      ViewerInfoMode.gif => 'GIF',
      ViewerInfoMode.video => tr(context, 'VIDEO'),
    };
    final controls = switch (mode) {
      ViewerInfoMode.image => tr(
        context,
        'LStick↑↓: Zoom  •  LStick←→: Switch  •  RStick: Pan  •  A/X: IPD  •  Y: Reset  •  B: Back  •  RB: UI',
      ),
      ViewerInfoMode.gif => tr(
        context,
        'LStick↑↓: Zoom  •  LStick←→: Switch  •  RStick: Pan  •  A/X: IPD  •  Y: Play/Pause  •  B: Back  •  RB: UI',
      ),
      ViewerInfoMode.video => tr(
        context,
        'DPad←/→: Seek ±5s  •  DPad↑/↓: Volume  •  LStick↑↓: Zoom  •  RStick: Pan  •  A/X: IPD  •  Y: Play/Pause  •  B: Back  •  RB: UI',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$mediaLabel${mediaLabel.isEmpty ? '' : '  '}${tr(context, 'Zoom')}: ${zoom.toStringAsFixed(1)}x   IPD: ${ipdOffset.toStringAsFixed(0)}px',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$index / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controls,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum ViewerInfoMode { image, gif, video }
