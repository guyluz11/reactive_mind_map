import 'package:flutter/material.dart';
import '../models/mind_map_data.dart';
import '../models/mind_map_style.dart';

/// markmap.js 스타일 마인드맵을 그리는 CustomPainter
class MarkmapPainter extends CustomPainter {
  final MindMapData data;
  final MindMapStyle style;
  final double animationValue;
  final String? selectedNodeId;
  final Function(String nodeId, Offset position)? onNodePositionCalculated;

  // 레이아웃 설정
  final double xSpacing = 200.0; // x축 간격
  final double ySpacing = 40.0; // y축 간격
  final double startX = 100.0; // 시작 x좌표

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

    // 루트 노드부터 시작
    _drawNode(canvas, data, Offset(startX, startY), nodePositions, 0);

    // 노드 위치 정보 콜백 호출
    if (onNodePositionCalculated != null) {
      nodePositions.forEach((nodeId, position) {
        onNodePositionCalculated!(nodeId, position);
      });
    }
  }

  /// 서브트리 전체 높이 계산
  double _subtreeHeight(MindMapData node, int level) {
    if (node.children.isEmpty) {
      return 40.0; // Default height
    }

    double childrenHeight = 0;
    for (final child in node.children) {
      childrenHeight += _subtreeHeight(child, level + 1) + ySpacing;
    }
    return childrenHeight - ySpacing; // 마지막 ySpacing 제외
  }

  /// 재귀적으로 노드 그리기
  void _drawNode(
    Canvas canvas,
    MindMapData node,
    Offset position,
    Map<String, Offset> nodePositions,
    int level,
  ) {
    final subtreeHeight = _subtreeHeight(node, level);

    // 자식 노드 y 시작점 계산
    double childY = position.dy - subtreeHeight / 2;

    // 자식 노드들 먼저 그리기 (재귀)
    for (final child in node.children) {
      final childSubtreeHeight = _subtreeHeight(child, level + 1);
      final childPos = Offset(
        position.dx + xSpacing,
        childY + childSubtreeHeight / 2,
      );

      // 연결선 그리기 (부드러운 곡선)
      if (animationValue > 0.3) {
        _drawConnection(canvas, position, childPos, node.color);
      }

      // 자식 노드 재귀 호출
      _drawNode(canvas, child, childPos, nodePositions, level + 1);

      childY += childSubtreeHeight + ySpacing;
    }

    // 위치 정보 저장
    nodePositions[node.id] = position;
  }

  /// 연결선 그리기 (베지어 곡선)
  void _drawConnection(Canvas canvas, Offset start, Offset end, Color? color) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // 부드러운 베지어 곡선
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
