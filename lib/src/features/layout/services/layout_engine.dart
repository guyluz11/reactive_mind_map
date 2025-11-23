import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/mind_map_constants.dart';
import '../../../core/enums/mind_map_layout.dart';
import '../../node/models/mind_map_node.dart';
import '../../node/models/mind_map_style.dart';

/// Engine responsible for calculating mind map layout
///
/// This class handles all layout-related calculations including:
/// - Canvas size calculation
/// - Root node positioning
/// - Subtree dimensions
/// - Node position assignment
class LayoutEngine {
  final MindMapStyle style;
  final Size minCanvasSize;
  final EdgeInsets canvasPadding;

  LayoutEngine({
    required this.style,
    this.minCanvasSize = const Size(
      MindMapConstants.defaultMinCanvasWidth,
      MindMapConstants.defaultMinCanvasHeight,
    ),
    this.canvasPadding = const EdgeInsets.all(
      MindMapConstants.defaultCanvasPadding,
    ),
  });

  /// Calculate the root node position based on layout type
  Offset calculateRootPosition(Size canvasSize) {
    switch (style.layout) {
      case MindMapLayout.right:
        return Offset(
          canvasPadding.left + MindMapConstants.defaultRootNodeOffset,
          canvasSize.height / 2,
        );
      case MindMapLayout.left:
        return Offset(
          canvasSize.width -
              canvasPadding.right -
              MindMapConstants.defaultRootNodeOffset,
          canvasSize.height / 2,
        );
      case MindMapLayout.top:
        return Offset(
          canvasSize.width / 2,
          canvasSize.height -
              canvasPadding.bottom -
              MindMapConstants.defaultRootNodeOffset,
        );
      case MindMapLayout.bottom:
        return Offset(
          canvasSize.width / 2,
          canvasPadding.top + MindMapConstants.defaultRootNodeOffset,
        );
      case MindMapLayout.radial:
      case MindMapLayout.horizontal:
      case MindMapLayout.vertical:
        return Offset(canvasSize.width / 2, canvasSize.height / 2);
    }
  }

  /// Calculate required canvas size based on node positions
  Size calculateRequiredCanvasSize(
    MindMapNode rootNode,
    List<MindMapNode> allVisibleNodes,
    List<MindMapNode> collapsedNodes,
  ) {
    if (allVisibleNodes.isEmpty) {
      return minCanvasSize;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    double maxNodeWidth = 0;
    double maxNodeHeight = 0;

    for (var node in allVisibleNodes) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      maxNodeWidth = math.max(maxNodeWidth, nodeSize.width);
      maxNodeHeight = math.max(maxNodeHeight, nodeSize.height);

      // Calculate node bounds (center based)
      final nodeLeft = node.position.dx - nodeSize.width / 2;
      final nodeRight = node.position.dx + nodeSize.width / 2;
      final nodeTop = node.position.dy - nodeSize.height / 2;
      final nodeBottom = node.position.dy + nodeSize.height / 2;

      minX = math.min(minX, nodeLeft);
      maxX = math.max(maxX, nodeRight);
      minY = math.min(minY, nodeTop);
      maxY = math.max(maxY, nodeBottom);
    }

    // Consider estimated bounds of collapsed nodes
    if (collapsedNodes.isNotEmpty) {
      final estimatedBounds = _estimateCollapsedNodesBounds(collapsedNodes);
      if (estimatedBounds != null) {
        minX = math.min(minX, estimatedBounds.left);
        maxX = math.max(maxX, estimatedBounds.right);
        minY = math.min(minY, estimatedBounds.top);
        maxY = math.max(maxY, estimatedBounds.bottom);
      }
    }

    // Calculate margins
    final nodeMargin = style.nodeMargin;

    // Minimum margin
    final minMargin = math.max(
      maxNodeWidth * MindMapConstants.minMarginMultiplier,
      MindMapConstants.minMarginFallback,
    );
    final extraPaddingX = math.max(minMargin, nodeMargin);
    final extraPaddingY = math.max(minMargin, nodeMargin);

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    // Canvas padding + extra padding
    final totalPaddingX = canvasPadding.horizontal + (extraPaddingX * 2);
    final totalPaddingY = canvasPadding.vertical + (extraPaddingY * 2);

    final requiredWidth = contentWidth + totalPaddingX;
    final requiredHeight = contentHeight + totalPaddingY;

    // Ensure minimum size
    final finalWidth = math.max(requiredWidth, minCanvasSize.width);
    final finalHeight = math.max(requiredHeight, minCanvasSize.height);

    // Extra margin for overflow protection
    return Size(
      finalWidth + MindMapConstants.defaultSafetyMarginX,
      finalHeight + MindMapConstants.defaultSafetyMarginY,
    );
  }

  /// Estimate bounds for collapsed nodes
  Rect? _estimateCollapsedNodesBounds(List<MindMapNode> collapsedNodes) {
    if (collapsedNodes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var node in collapsedNodes) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      // Estimate expanded area based on current position
      double expandedWidth = nodeSize.width;
      double expandedHeight = nodeSize.height;

      // Estimated size considering child count
      if (node.children.isNotEmpty) {
        final childCount = node.children.length;
        final estimatedSpacing = style.levelSpacing;

        switch (style.layout) {
          case MindMapLayout.right:
          case MindMapLayout.left:
          case MindMapLayout.horizontal:
            expandedWidth += estimatedSpacing;
            expandedHeight += childCount * (nodeSize.height + style.nodeMargin);
            break;
          case MindMapLayout.top:
          case MindMapLayout.bottom:
          case MindMapLayout.vertical:
            expandedWidth += childCount * (nodeSize.width + style.nodeMargin);
            expandedHeight += estimatedSpacing;
            break;
          case MindMapLayout.radial:
            final radius =
                estimatedSpacing *
                MindMapConstants.radialLayoutRadiusMultiplier;
            expandedWidth += radius * 2;
            expandedHeight += radius * 2;
            break;
        }
      }

      final nodeLeft = node.position.dx - expandedWidth / 2;
      final nodeRight = node.position.dx + expandedWidth / 2;
      final nodeTop = node.position.dy - expandedHeight / 2;
      final nodeBottom = node.position.dy + expandedHeight / 2;

      minX = math.min(minX, nodeLeft);
      maxX = math.max(maxX, nodeRight);
      minY = math.min(minY, nodeTop);
      maxY = math.max(maxY, nodeBottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculate subtree heights recursively
  double calculateSubtreeHeights(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(node.id)) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      return nodeSize.height + style.nodeMargin;
    }
    visited.add(node.id);

    if (node.children.isEmpty) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      node.subtreeHeight = nodeSize.height + style.nodeMargin;
      return node.subtreeHeight;
    }

    double totalChildHeight = 0;
    for (var child in node.children) {
      totalChildHeight += calculateSubtreeHeights(
        child,
        visited: Set.from(visited),
      );
    }

    final nodeSize = style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    final additionalMargin =
        nodeSize.height * MindMapConstants.additionalMarginMultiplier;
    final minSpacing = style.nodeMargin * MindMapConstants.minSpacingMultiplier;

    final childCountFactor = math.max(
      1.0,
      node.children.length * MindMapConstants.childCountSpacingMultiplier,
    );
    final expandedMargin = additionalMargin * childCountFactor;

    node.subtreeHeight = math.max(
      totalChildHeight + minSpacing,
      nodeSize.height + style.nodeMargin + expandedMargin,
    );

    return node.subtreeHeight;
  }

  /// Calculate subtree widths recursively
  double calculateSubtreeWidths(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(node.id)) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      return nodeSize.width + style.nodeMargin;
    }
    visited.add(node.id);

    if (node.children.isEmpty) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      node.subtreeWidth = nodeSize.width + style.nodeMargin;
      return node.subtreeWidth;
    }

    double totalChildWidth = 0;
    for (var child in node.children) {
      totalChildWidth += calculateSubtreeWidths(
        child,
        visited: Set.from(visited),
      );
    }

    final nodeSize = style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    final additionalMargin =
        nodeSize.width * MindMapConstants.additionalMarginMultiplier;
    final minSpacing = style.nodeMargin * MindMapConstants.minSpacingMultiplier;

    final childCountFactor = math.max(
      1.0,
      node.children.length * MindMapConstants.childCountSpacingMultiplier,
    );
    final expandedMargin = additionalMargin * childCountFactor;

    node.subtreeWidth = math.max(
      totalChildWidth + minSpacing,
      nodeSize.width + style.nodeMargin + expandedMargin,
    );

    return node.subtreeWidth;
  }

  /// Calculate dynamic level spacing based on node sizes
  double calculateDynamicSpacing(MindMapNode parent, int level) {
    final parentSize = style.getActualNodeSize(
      parent.level,
      measuredSize: parent.measuredSize,
    );

    double maxChildSize = 0;
    for (var child in parent.children) {
      final childSize = style.getActualNodeSize(
        child.level,
        measuredSize: child.measuredSize,
      );
      maxChildSize = math.max(
        maxChildSize,
        math.max(childSize.width, childSize.height),
      );
    }

    final baseSpacing = style.levelSpacing;
    final parentMaxSize = math.max(parentSize.width, parentSize.height);

    final nodeBasedSpacing =
        (parentMaxSize + maxChildSize) / 2 +
        MindMapConstants.nodeBasedSpacingOffset;
    final childCountFactor = math.max(
      1.0,
      parent.children.length * MindMapConstants.childCountFactorMultiplier,
    );
    final levelFactor = math.max(
      1.0,
      level * MindMapConstants.levelSpacingMultiplier,
    );

    final dynamicSpacing = nodeBasedSpacing * childCountFactor * levelFactor;
    final minSpacing = baseSpacing + MindMapConstants.minDynamicSpacing;

    return math.max(minSpacing, dynamicSpacing);
  }

  /// Calculate gap between child nodes
  double calculateChildGap(List<MindMapNode> children) {
    if (children.isEmpty) return 0.0;

    // Calculate average size of child nodes
    double avgNodeSize = 0.0;
    for (var child in children) {
      final childSize = style.getActualNodeSize(
        child.level,
        measuredSize: child.measuredSize,
      );
      avgNodeSize += math.max(childSize.width, childSize.height);
    }
    avgNodeSize /= children.length;

    // Default spacing + node size based spacing
    final baseGap = style.nodeMargin;
    final sizeBasedGap = avgNodeSize * MindMapConstants.childGapSizeMultiplier;
    final childCountFactor = math.min(
      children.length * MindMapConstants.childCountFactorMultiplier,
      MindMapConstants.maxChildCountFactor,
    ); // Spacing increases with more children (max 2x)

    return (baseGap + sizeBasedGap) * childCountFactor;
  }
}
