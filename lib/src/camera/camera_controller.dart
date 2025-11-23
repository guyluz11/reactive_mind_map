import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/mind_map_constants.dart';
import '../core/enums/camera_focus.dart';
import '../features/node/models/mind_map_node.dart';
import '../features/node/models/mind_map_style.dart';

/// Controller for managing camera/viewport operations in the mind map
///
/// This class handles:
/// - Camera focusing on nodes
/// - Viewport transformations
/// - Animated camera movements
/// - Fitting nodes into view
class MindMapCameraController {
  final TransformationController transformationController;
  final MindMapStyle style;
  final TickerProvider vsync;

  MindMapCameraController({
    required this.transformationController,
    required this.style,
    required this.vsync,
  });

  /// Perform center view based on camera focus mode
  void performCenterView({
    required CameraFocus cameraFocus,
    required Size viewportSize,
    required Size canvasSize,
    required Offset rootPosition,
    required double initialScale,
    required Duration focusAnimation,
    required EdgeInsets focusMargin,
    String? focusNodeId,
    MindMapNode? rootNode,
    Offset? centerOffset,
    bool autoCenterOnScreen = false,
    BuildContext? context,
  }) {
    double scale = initialScale;
    Offset targetPosition = rootPosition;

    switch (cameraFocus) {
      case CameraFocus.rootNode:
        targetPosition = rootPosition;
        break;

      case CameraFocus.center:
        targetPosition = Offset(canvasSize.width / 2, canvasSize.height / 2);
        break;

      case CameraFocus.allNodes:
        if (rootNode != null) {
          final bounds = _calculateNodeBounds(rootNode);
          targetPosition = bounds.center;
          scale = _calculateFitScale(bounds.size, viewportSize, focusMargin);
        }
        break;

      case CameraFocus.firstLeaf:
        if (rootNode != null) {
          final firstLeaf = _findFirstLeaf(rootNode);
          if (firstLeaf != null) {
            targetPosition = firstLeaf.position;
          }
        }
        break;

      case CameraFocus.custom:
        if (focusNodeId != null && rootNode != null) {
          final targetNode = _findNodeById(rootNode, focusNodeId);
          if (targetNode != null) {
            targetPosition = targetNode.position;
          }
        }
        break;

      case CameraFocus.fitAllNodes:
        if (rootNode != null) {
          final bounds = _calculateNodeBounds(rootNode);
          targetPosition = bounds.center;
          scale = _calculateFitScale(bounds.size, viewportSize, focusMargin);
        }
        break;
    }

    // Apply center offset and auto-center logic
    double horizontalOffset = centerOffset?.dx ?? 0.0;
    double verticalOffset = centerOffset?.dy ?? 0.0;

    if (autoCenterOnScreen && context != null) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final globalPos = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final screenCenterY = screenHeight / 2;
        final widgetCenterY = globalPos.dy + renderBox.size.height / 2;
        verticalOffset += (widgetCenterY - screenCenterY);
      }
    }

    // Calculate transformation
    final viewportCenterX = viewportSize.width / 2;
    final viewportCenterY = viewportSize.height / 2;

    final double tx =
        viewportCenterX / scale - targetPosition.dx - horizontalOffset;
    final double ty =
        viewportCenterY / scale - targetPosition.dy - verticalOffset;

    final newTransform =
        Matrix4.identity()
          // ignore: deprecated_member_use
          ..scale(scale, scale, 1.0)
          // ignore: deprecated_member_use
          ..translate(tx, ty, 0.0);

    // Animate or apply immediately
    if (focusAnimation.inMilliseconds > 0) {
      _animateToTransform(newTransform, focusAnimation);
    } else {
      transformationController.value = newTransform;
    }
  }

  /// Focus camera on a specific node by ID
  void focusOnNodeById({
    required String nodeId,
    required MindMapNode rootNode,
    required Size viewportSize,
    required Duration focusAnimation,
    bool enablePanAndZoom = true,
  }) {
    if (!enablePanAndZoom) return;

    final targetNode = _findNodeById(rootNode, nodeId);
    if (targetNode == null) return;

    final currentTransform = transformationController.value;
    final currentScale = currentTransform.getMaxScaleOnAxis();

    final viewportCenterX = viewportSize.width / 2;
    final viewportCenterY = viewportSize.height / 2;

    final double tx = viewportCenterX / currentScale - targetNode.position.dx;
    final double ty =
        viewportCenterY / currentScale -
        targetNode.position.dy -
        MindMapConstants.verticalOffsetCorrection;

    final newTransform =
        Matrix4.identity()
          // ignore: deprecated_member_use
          ..scale(currentScale, currentScale, 1.0)
          // ignore: deprecated_member_use
          ..translate(tx, ty, 0.0);

    if (focusAnimation.inMilliseconds > 0) {
      _animateToTransform(newTransform, focusAnimation);
    } else {
      transformationController.value = newTransform;
    }
  }

  /// Fit a list of nodes into the viewport
  void fitNodesToView({
    required List<MindMapNode> nodes,
    required Size viewportSize,
    required Duration focusAnimation,
    required EdgeInsets focusMargin,
  }) {
    if (nodes.isEmpty) return;

    final bounds = _calculateMultipleNodesBounds(nodes);
    final targetPosition = bounds.center;
    final scale = _calculateFitScale(bounds.size, viewportSize, focusMargin);

    final viewportCenterX = viewportSize.width / 2;
    final viewportCenterY = viewportSize.height / 2;

    final double tx = viewportCenterX / scale - targetPosition.dx;
    final double ty = viewportCenterY / scale - targetPosition.dy;

    final newTransform =
        Matrix4.identity()
          // ignore: deprecated_member_use
          ..scale(scale, scale, 1.0)
          // ignore: deprecated_member_use
          ..translate(tx, ty, 0.0);

    if (focusAnimation.inMilliseconds > 0) {
      _animateToTransform(newTransform, focusAnimation);
    } else {
      transformationController.value = newTransform;
    }
  }

  /// Fit an entire subtree into view
  void fitSubtreeToView({
    required MindMapNode node,
    required Size viewportSize,
    required Duration focusAnimation,
    required EdgeInsets focusMargin,
  }) {
    final allNodes = _collectAllVisibleNodes(node);
    fitNodesToView(
      nodes: allNodes,
      viewportSize: viewportSize,
      focusAnimation: focusAnimation,
      focusMargin: focusMargin,
    );
  }

  // Private helper methods

  void _animateToTransform(Matrix4 targetTransform, Duration duration) {
    final AnimationController animController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final Matrix4Tween tween = Matrix4Tween(
      begin: transformationController.value,
      end: targetTransform,
    );

    final Animation<Matrix4> animation = tween.animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInOut),
    );

    animation.addListener(() {
      transformationController.value = animation.value;
    });

    animController.forward().then((_) {
      animController.dispose();
    });
  }

  Rect _calculateNodeBounds(MindMapNode node) {
    final allNodes = _collectAllVisibleNodes(node);
    return _calculateMultipleNodesBounds(allNodes);
  }

  Rect _calculateMultipleNodesBounds(List<MindMapNode> nodes) {
    if (nodes.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var node in nodes) {
      final nodeSize = style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      final nodeLeft = node.position.dx - nodeSize.width / 2;
      final nodeRight = node.position.dx + nodeSize.width / 2;
      final nodeTop = node.position.dy - nodeSize.height / 2;
      final nodeBottom = node.position.dy + nodeSize.height / 2;

      minX = math.min(minX, nodeLeft);
      maxX = math.max(maxX, nodeRight);
      minY = math.min(minY, nodeTop);
      maxY = math.max(maxY, nodeBottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _calculateFitScale(
    Size contentSize,
    Size viewportSize,
    EdgeInsets margin,
  ) {
    final availableWidth = viewportSize.width - margin.horizontal;
    final availableHeight = viewportSize.height - margin.vertical;

    final scaleX = availableWidth / contentSize.width;
    final scaleY = availableHeight / contentSize.height;

    return math.min(scaleX, scaleY).clamp(0.1, 3.0);
  }

  MindMapNode? _findFirstLeaf(MindMapNode node) {
    if (node.children.isEmpty) return node;
    return _findFirstLeaf(node.children.first);
  }

  MindMapNode? _findNodeById(MindMapNode node, String id) {
    if (node.id == id) return node;

    for (var child in node.children) {
      final result = _findNodeById(child, id);
      if (result != null) return result;
    }

    return null;
  }

  List<MindMapNode> _collectAllVisibleNodes(MindMapNode node) {
    final List<MindMapNode> result = [node];

    if (node.isExpanded) {
      for (var child in node.children) {
        result.addAll(_collectAllVisibleNodes(child));
      }
    }

    return result;
  }
}
