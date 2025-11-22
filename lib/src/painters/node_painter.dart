import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../enums/node_shape.dart';

/// Painter for drawing various node shapes
class NodePainter {
  /// Draw node with specified shape
  static void paintNode({
    required Canvas canvas,
    required Rect rect,
    required NodeShape shape,
    required Paint fillPaint,
    Paint? borderPaint,
  }) {
    switch (shape) {
      case NodeShape.roundedRectangle:
        _paintRoundedRectangle(canvas, rect, fillPaint, borderPaint);
        break;
      case NodeShape.circle:
        _paintCircle(canvas, rect, fillPaint, borderPaint);
        break;
      case NodeShape.rectangle:
        _paintRectangle(canvas, rect, fillPaint, borderPaint);
        break;
      case NodeShape.diamond:
        _paintDiamond(canvas, rect, fillPaint, borderPaint);
        break;
      case NodeShape.hexagon:
        _paintHexagon(canvas, rect, fillPaint, borderPaint);
        break;
      case NodeShape.ellipse:
        _paintEllipse(canvas, rect, fillPaint, borderPaint);
        break;
    }
  }

  /// Draw rounded rectangle
  static void _paintRoundedRectangle(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, fillPaint);
    if (borderPaint != null) {
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  /// Draw circle
  static void _paintCircle(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) / 2;
    canvas.drawCircle(center, radius, fillPaint);
    if (borderPaint != null) {
      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  /// Draw rectangle
  static void _paintRectangle(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    canvas.drawRect(rect, fillPaint);
    if (borderPaint != null) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  /// Draw diamond
  static void _paintDiamond(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final path = Path();
    final center = rect.center;
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;

    path.moveTo(center.dx, center.dy - halfHeight); // top
    path.lineTo(center.dx + halfWidth, center.dy); // right
    path.lineTo(center.dx, center.dy + halfHeight); // bottom
    path.lineTo(center.dx - halfWidth, center.dy); // left
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null) {
      canvas.drawPath(path, borderPaint);
    }
  }

  /// Draw hexagon
  static void _paintHexagon(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final path = Path();
    final center = rect.center;
    final size = math.min(rect.width, rect.height) / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null) {
      canvas.drawPath(path, borderPaint);
    }
  }

  /// Draw ellipse
  static void _paintEllipse(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    canvas.drawOval(rect, fillPaint);
    if (borderPaint != null) {
      canvas.drawOval(rect, borderPaint);
    }
  }
}
