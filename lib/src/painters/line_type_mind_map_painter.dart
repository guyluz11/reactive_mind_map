import 'package:flutter/material.dart';
// import 'dart:math' as math;
import '../models/mind_map_data.dart';
import '../models/mind_map_style.dart';

class LineTypeMindMapPainter extends CustomPainter {
  final MindMapData data;
  final MindMapStyle style;
  final double animationValue;
  final String? selectedNodeId;
  final Function(String nodeId, Offset position)? onNodePositionCalculated;

  LineTypeMindMapPainter({
    required this.data,
    required this.style,
    this.animationValue = 1.0,
    this.selectedNodeId,
    this.onNodePositionCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX = 100.0;
    final startY = size.height / 2;
    final levelSpacing = 200.0;

    final Map<String, Offset> nodePositions = {};

    _drawRootNode(canvas, Offset(startX, startY), data, nodePositions);

    _drawBranchesHorizontal(
      canvas,
      Offset(startX, startY),
      data.children,
      nodePositions,
      size,
      levelSpacing,
    );

    if (onNodePositionCalculated != null) {
      nodePositions.forEach((nodeId, position) {
        onNodePositionCalculated!(nodeId, position);
      });
    }
  }

  void _drawRootNode(
    Canvas canvas,
    Offset position,
    MindMapData node,
    Map<String, Offset> nodePositions,
  ) {
    final isSelected = selectedNodeId == node.id;

    final dotPaint =
        Paint()
          ..color = node.color ?? style.getDefaultNodeColor(0)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 6, dotPaint);

    if (isSelected) {
      final selectionPaint =
          Paint()
            ..color = style.selectionBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.selectionBorderWidth;

      canvas.drawCircle(position, 8, selectionPaint);
    }

    nodePositions[node.id] = position;
  }

  void _drawBranchesHorizontal(
    Canvas canvas,
    Offset parentPosition,
    List<MindMapData> branches,
    Map<String, Offset> nodePositions,
    Size canvasSize,
    double levelSpacing,
  ) {
    if (branches.isEmpty) return;

    final totalHeight = branches.length * 80.0;
    final startY = parentPosition.dy - totalHeight / 2;

    for (int i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final branchY = startY + i * 80.0;
      final branchPosition = Offset(parentPosition.dx + levelSpacing, branchY);

      _drawMarkmapNode(
        canvas,
        parentPosition,
        branchPosition,
        branch,
        nodePositions,
        canvasSize,
        1,
      );
    }
  }

  void _drawMarkmapNode(
    Canvas canvas,
    Offset parentPosition,
    Offset nodePosition,
    MindMapData node,
    Map<String, Offset> nodePositions,
    Size canvasSize,
    int level,
  ) {
    final isSelected = selectedNodeId == node.id;

    if (animationValue > 0.3) {
      final path = _createMarkmapCurve(parentPosition, nodePosition);
      final linePaint =
          Paint()
            ..color = node.color ?? style.getDefaultNodeColor(level)
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.connectionWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);
    }

    if (animationValue > 0.5) {
      final dotPaint =
          Paint()
            ..color = node.color ?? style.getDefaultNodeColor(level)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePosition, 5, dotPaint);

      if (isSelected) {
        final selectionPaint =
            Paint()
              ..color = style.selectionBorderColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.selectionBorderWidth;

        canvas.drawCircle(nodePosition, 7, selectionPaint);
      }
    }

    nodePositions[node.id] = nodePosition;

    if (node.children.isNotEmpty && animationValue > 0.8) {
      final childSpacing = 60.0;
      final totalChildHeight = node.children.length * childSpacing;
      final startChildY = nodePosition.dy - totalChildHeight / 2;

      for (int i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        final childY = startChildY + i * childSpacing;
        final childPosition = Offset(nodePosition.dx + 150.0, childY);

        _drawMarkmapNode(
          canvas,
          nodePosition,
          childPosition,
          child,
          nodePositions,
          canvasSize,
          level + 1,
        );
      }
    }
  }

  Path _createMarkmapCurve(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final controlDistance = 50.0;
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

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
