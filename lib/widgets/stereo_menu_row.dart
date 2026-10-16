import 'package:flutter/material.dart';

/// A single logical menu row rendered once for each eye.
///
/// This widget deliberately owns no scrolling or business state. Put it
/// *inside* the page's only ListView so a drag from either half of the screen
/// drives the same ScrollPosition.
class StereoMenuRow extends StatelessWidget {
  const StereoMenuRow({
    super.key,
    required this.builder,
    this.excludeRightSemantics = true,
    this.scale = 1.0,
  });

  final Widget Function(BuildContext context, StereoMenuEye eye) builder;
  final bool excludeRightSemantics;
  final double scale;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _scaled(builder(context, StereoMenuEye.left))),
      Expanded(
        child: excludeRightSemantics
            ? ExcludeSemantics(
                child: _scaled(builder(context, StereoMenuEye.right)),
              )
            : _scaled(builder(context, StereoMenuEye.right)),
      ),
    ],
  );

  Widget _scaled(Widget child) => scale == 1.0
      ? child
      : Transform.scale(scale: scale.clamp(0.5, 1.0), child: child);
}

enum StereoMenuEye { left, right }
