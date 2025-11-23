import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Widget that measures its child's size and reports it via callback.
class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({super.key, required this.onChange, required this.child});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
    return Container(key: widget.key, child: widget.child);
  }

  void _postFrameCallback(_) {
    if (!mounted) return;
    final context = this.context;
    final size = context.size;
    if (size != null) {
      widget.onChange(size);
    }
  }
}
