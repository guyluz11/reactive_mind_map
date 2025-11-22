import 'package:flutter/material.dart';

import 'mind_map_data.dart';

/// Mind map node class for internal processing
class MindMapNode {
  /// Node ID
  final String id;

  /// Node content
  final Widget content;

  /// Node description
  final String description;

  /// Child nodes
  final List<MindMapNode> children;

  /// Expansion state
  bool isExpanded;

  /// Current position
  Offset position;

  /// Target position
  Offset targetPosition;

  /// Node color
  Color color;

  /// Border color
  Color? borderColor;

  /// Measured node size (after widget rendering)
  Size? measuredSize;

  /// Animation state
  bool isAnimating;

  /// Whether position is fixed
  bool hasFixedPosition;

  /// Subtree height
  double subtreeHeight;

  /// Subtree width (for vertical layout)
  double subtreeWidth;

  /// Minimum Y coordinate
  double minY;

  /// Maximum Y coordinate
  double maxY;

  /// Node level
  int level;

  /// Directional relationship with parent (for directional consistency)
  String? parentDirection;

  /// Custom user data
  final Map<String, dynamic>? customData;

  MindMapNode({
    required this.id,
    required this.content,
    required this.description,
    this.children = const [],
    this.isExpanded = false,
    this.position = Offset.zero,
    this.targetPosition = Offset.zero,
    this.color = Colors.blue,
    this.borderColor,
    this.isAnimating = false,
    this.hasFixedPosition = false,
    this.subtreeHeight = 0,
    this.subtreeWidth = 0,
    this.minY = 0,
    this.maxY = 0,
    this.level = 0,
    this.parentDirection,
    this.customData,
  });

  /// Factory method to create MindMapNode from MindMapData
  factory MindMapNode.fromData(
    MindMapData data,
    int level, {
    List<Color>? defaultColors,
  }) {
    final defaultNodeColors =
        defaultColors ??
        [
          const Color(0xFF2563EB),
          const Color(0xFF7C3AED),
          const Color(0xFF059669),
          const Color(0xFFDC2626),
          const Color(0xFFF59E0B),
          const Color(0xFF7C2D12),
          const Color(0xFF6B21A8),
          const Color(0xFF0EA5E9),
          const Color(0xFF10B981),
          const Color(0xFF8B5CF6),
          const Color(0xFF06B6D4),
          const Color(0xFFF97316),
        ];

    final children =
        data.children
            .map(
              (childData) => MindMapNode.fromData(
                childData,
                level + 1,
                defaultColors: defaultColors,
              ),
            )
            .toList();

    return MindMapNode(
      id: data.id,
      content: data.content,
      description: data.description,
      children: children,
      color: data.color ?? defaultNodeColors[level % defaultNodeColors.length],
      borderColor: data.borderColor,
      level: level,
      customData: data.customData,
    );
  }

  /// Check if node has children
  bool get hasChildren => children.isNotEmpty;

  /// Check if node is a leaf node
  bool get isLeaf => children.isEmpty;

  @override
  String toString() {
    return 'MindMapNode(id: $id, level: $level, children: ${children.length})';
  }
}
