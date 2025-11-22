import 'package:flutter/material.dart';
import '../models/mind_map_data.dart';
import '../models/mind_map_style.dart';

/// CustomPainter for drawing markmap.js style mind map
class MarkmapPainter extends CustomPainter {
  final MindMapData data;
  final MindMapStyle style;
  final double animationValue;
  final String? selectedNodeId;
  final Function(String nodeId, Offset position)? onNodePositionCalculated;

  // Layout settings
  final double xSpacing = 200.0; // x-axis spacing
  final double ySpacing = 40.0; // y-axis spacing
  final double startX = 100.0; // starting x coordinate

  MarkmapPainter({
    required this.data,
    required this.style,
    this.animationValue = 1.0,
    this.selectedNodeId,
    this.onNodePositionCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startY = size.height / 2;
    final nodePositions = <String, Offset>{};

    // Start from root node
    _drawNode(canvas, data, Offset(startX, startY), nodePositions, 0);

    // Call node position info callback
    if (onNodePositionCalculated != null) {
      nodePositions.forEach((nodeId, position) {
        onNodePositionCalculated!(nodeId, position);
      });
    }
  }

  /// Calculate total subtree height
  double _subtreeHeight(MindMapData node, int level) {
    if (node.children.isEmpty) {
      return 40.0; // Default height
    }

    double childrenHeight = 0;
    for (final child in node.children) {
      childrenHeight += _subtreeHeight(child, level + 1) + ySpacing;
    }
    return childrenHeight - ySpacing; // Exclude last ySpacing
  }

  /// Draw nodes recursively
  void _drawNode(
    Canvas canvas,
    MindMapData node,
    Offset position,
    Map<String, Offset> nodePositions,
    int level,
  ) {
    final subtreeHeight = _subtreeHeight(node, level);

    // Calculate child node y starting point
    double childY = position.dy - subtreeHeight / 2;

    // Draw child nodes first (recursive)
    for (final child in node.children) {
      final childSubtreeHeight = _subtreeHeight(child, level + 1);
      final childPos = Offset(
        position.dx + xSpacing,
        childY + childSubtreeHeight / 2,
      );

      // Draw connection line (smooth curve)
      if (animationValue > 0.3) {
        _drawConnection(canvas, position, childPos, node.color);
      }

      // Recursive call for child node
      _drawNode(canvas, child, childPos, nodePositions, level + 1);

      childY += childSubtreeHeight + ySpacing;
    }

    // Save position info
    nodePositions[node.id] = position;
  }

  /// Draw connection line (Bezier curve)
  void _drawConnection(Canvas canvas, Offset start, Offset end, Color? color) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Smooth Bezier curve
    final controlDistance = xSpacing * 0.3;
    final controlPoint1 = Offset(start.dx + controlDistance, start.dy);
    final controlPoint2 = Offset(end.dx - controlDistance, end.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    final paint =
        Paint()
          ..color = color ?? style.getDefaultNodeColor(1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.connectionWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
