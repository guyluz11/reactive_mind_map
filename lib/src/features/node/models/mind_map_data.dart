import 'package:flutter/material.dart';

/// Class representing mind map node data
class MindMapData {
  /// Unique identifier of the node
  final String id;

  /// Content widget of the node
  final Widget content;

  /// Detailed description of the node
  final String description;

  /// Child nodes
  final List<MindMapData> children;

  /// Color of the node (uses default color if null)
  final Color? color;

  /// Border color of the node (uses default color if null)
  final Color? borderColor;

  /// Custom user data
  final Map<String, dynamic>? customData;

  const MindMapData({
    required this.id,
    required this.content,
    this.description = '',
    this.children = const [],
    this.color,
    this.borderColor,
    this.customData,
  });

  /// copyWith method for copying data
  MindMapData copyWith({
    String? id,
    Widget? content,
    String? description,
    List<MindMapData>? children,
    Color? color,
    Color? borderColor,
    Map<String, dynamic>? customData,
  }) {
    return MindMapData(
      id: id ?? this.id,
      content: content ?? this.content,
      description: description ?? this.description,
      children: children ?? this.children,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      customData: customData ?? this.customData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MindMapData &&
        other.id == id &&
        other.content == content &&
        other.description == description &&
        other.children == children &&
        other.color == color &&
        other.borderColor == borderColor &&
        other.customData == customData;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      description,
      children,
      color,
      borderColor,
      color,
      borderColor,
      customData,
    );
  }

  @override
  String toString() {
    return 'MindMapData(id: $id, children:  [36m${children.length} [0m)';
  }

  /// Returns a flat list of all nodes in pre-order traversal (self, then children)
  List<MindMapData> flatten() {
    List<MindMapData> result = [this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  /// Recursively update a node in the tree.
  static MindMapData updateNodeInTree(
    MindMapData root,
    String nodeId,
    MindMapData Function(MindMapData) updater,
  ) {
    if (root.id == nodeId) {
      return updater(root);
    }

    List<MindMapData> newChildren = [];
    bool wasUpdated = false;
    for (final child in root.children) {
      final updatedChild = updateNodeInTree(child, nodeId, updater);
      if (updatedChild != child) {
        wasUpdated = true;
      }
      newChildren.add(updatedChild);
    }

    if (wasUpdated) {
      return root.copyWith(children: newChildren);
    }

    return root;
  }
}
