import 'package:flutter/material.dart';

/// 左右分屏包装器，仅用于静态、不可滚动的内容（例如 busy 覆盖层）。
///
/// 不要用它包装 ListView、CustomScrollView 或任何包含 Scrollable 的子树；
/// 交互式 VR 菜单必须在唯一的 Scrollable 内使用 [StereoMenuRow] 按行复制。
class MirrorSplitView extends StatelessWidget {
  final WidgetBuilder builder;

  const MirrorSplitView({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: builder(context)),
        Expanded(child: builder(context)),
      ],
    );
  }
}
