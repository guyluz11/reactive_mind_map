import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/enums/camera_focus.dart';
import '../../../core/enums/mind_map_layout.dart';
import '../../../core/enums/node_shape.dart';
import '../../node/models/mind_map_data.dart';
import '../../node/models/mind_map_node.dart';
import '../../node/models/mind_map_style.dart';
// import '../enums/mind_map_type.dart';
import '../../edge/painters/mind_map_painter.dart';
import '../../../core/widgets/measure_size.dart';
// import 'markmap_widget.dart'; // in development

/// Customizable mind map widget
class MindMapWidget extends StatefulWidget {
  /// Mind map data
  final MindMapData data;

  /// Mind map style
  final MindMapStyle style;

  /// Node tap callback
  final Function(MindMapData node)? onNodeTap;

  /// Node long press callback
  final Function(MindMapData node)? onNodeLongPress;

  /// Node double tap callback
  final Function(MindMapData node)? onNodeDoubleTap;

  /// Expand/collapse state change callback
  final Function(MindMapData node, bool isExpanded)? onNodeExpandChanged;

  /// Canvas size (auto-calculated if null)
  final Size? canvasSize;

  /// Interactive viewer options
  final InteractiveViewerOptions? viewerOptions;

  /// Minimum canvas size
  final Size minCanvasSize;

  /// Canvas padding
  final EdgeInsets canvasPadding;

  /// Optional key to capture the full mind map canvas (wraps canvas in RepaintBoundary) to give the user the ability to save the mind map as an image
  final GlobalKey? captureKey;

  /// Whether nodes should be collapsed by default (false = open all nodes)
  final bool isNodesCollapsed;

  /// Initial zoom scale for the mind map (1.0 = no zoom)
  final double initialScale;

  /// Animation duration for camera movements
  final Duration cameraAnimationDuration;

  /// Camera behavior when expanding nodes
  final NodeExpandCameraBehavior nodeExpandCameraBehavior;

  /// Background widget
  final Widget? backgroundWidget;

  /// Optional offset to adjust the camera center point.
  /// Useful when the widget is partially obscured or visually centered differently.
  final Offset? centerOffset;

  /// Enable debug mode to show center marker and logs
  final bool debugMode;

  /// Automatically adjust center offset to align with the screen center.
  /// Useful when the widget is not full screen (e.g. in a bottom sheet or column).
  final bool autoCenterOnScreen;

  const MindMapWidget({
    super.key,
    required this.data,
    this.style = const MindMapStyle(),
    this.onNodeTap,
    this.onNodeLongPress,
    this.onNodeDoubleTap,
    this.onNodeExpandChanged,
    this.canvasSize,
    this.viewerOptions,
    this.minCanvasSize = const Size(1200, 800),
    this.canvasPadding = const EdgeInsets.all(300),
    this.isNodesCollapsed = false,
    this.initialScale = 1.0,
    this.captureKey,
    this.cameraAnimationDuration = const Duration(seconds: 1),
    this.nodeExpandCameraBehavior = NodeExpandCameraBehavior.none,
    this.backgroundWidget,
    this.centerOffset,
    this.debugMode = false,
    this.autoCenterOnScreen = false,
  });

  @override
  State<MindMapWidget> createState() => MindMapWidgetState();
}

/// Interactive viewer options
class InteractiveViewerOptions {
  final bool constrained;
  final EdgeInsets boundaryMargin;
  final double minScale;
  final double maxScale;
  final bool enablePanAndZoom;

  const InteractiveViewerOptions({
    this.constrained = false,
    this.boundaryMargin = const EdgeInsets.all(100),
    this.minScale = 0.1,
    this.maxScale = 3.0,
    this.enablePanAndZoom = true,
  });
}

class MindMapWidgetState extends State<MindMapWidget>
    with TickerProviderStateMixin {
  // Controller to manage initial centering in InteractiveViewer
  late TransformationController _transformationController;
  late MindMapNode rootNode;
  final List<AnimationController> _activeAnimations = [];
  String? _selectedNodeId;

  Size _actualCanvasSize = const Size(1200, 800);
  late Offset _rootPosition;

  bool _isTogglingNode = false;
  bool _isInitialLoad = true;
  Timer? _stabilizationTimer;

  // New camera navigation state
  int _currentFocusedNodeIndex = 0;
  List<MindMapNode> _focusableNodes = [];

  @override
  void initState() {
    super.initState();
    // Initialize transformation controller for centering
    _transformationController = TransformationController();
    _initializeMindMap();
    _calculateCanvasAndLayout();

    // Center the root after first frame if pan/zoom is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.viewerOptions?.enablePanAndZoom ?? true)) {
        _centerView();
      }

      // Disable initial load state after a stabilization period
      // This allows the layout to settle (MeasureSize callbacks) before we stop auto-centering
      _stabilizationTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isInitialLoad = false;
          });
        }
      });
    });
  }

  @override
  void didUpdateWidget(MindMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the data or style is changed, recalculate the entire layout
    if (oldWidget.data != widget.data ||
        oldWidget.style != widget.style ||
        oldWidget.isNodesCollapsed != widget.isNodesCollapsed ||
        oldWidget.initialScale != widget.initialScale) {
      _initializeMindMap();
      // Re-center after layout updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateCanvasAndLayout();
          // Only auto-center if not toggling node
          if ((widget.viewerOptions?.enablePanAndZoom ?? true) &&
              !_isTogglingNode) {
            _centerView();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _stabilizationTimer?.cancel();
    _transformationController.dispose();
    for (var controller in _activeAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Initialize mind map
  void _initializeMindMap() {
    rootNode = MindMapNode.fromData(
      widget.data,
      0,
      defaultColors: widget.style.defaultNodeColors,
    );
    // apply default expansion/collapse to all nodes
    _applyInitialExpansion(rootNode);
  }

  /// Recursively set each node's expanded state based on the isNodesCollapsed flag
  void _applyInitialExpansion(MindMapNode node) {
    node.isExpanded = !widget.isNodesCollapsed;
    for (var child in node.children) {
      _applyInitialExpansion(child);
    }
  }

  /// Calculate canvas size and layout
  void _calculateCanvasAndLayout() {
    if (!mounted) return;

    debugPrint('🔄 _calculateCanvasAndLayout called');

    try {
      _actualCanvasSize = widget.canvasSize ?? widget.minCanvasSize;

      if (!_isTogglingNode) {
        _calculateRootPosition();
      }
      _calculateSubtreeHeights(rootNode);
      _calculateSubtreeWidths(rootNode);
      _assignPositions(rootNode, 0);

      if (widget.canvasSize == null) {
        final requiredSize = _calculateRequiredCanvasSize();

        if (_actualCanvasSize != requiredSize) {
          _actualCanvasSize = requiredSize;
          _resetNodePositions(rootNode);

          if (!_isTogglingNode) {
            _calculateRootPosition();
          }
          _calculateSubtreeHeights(rootNode);
          _calculateSubtreeWidths(rootNode);
          _assignPositions(rootNode, 0);
        }
      }

      if (mounted) {
        setState(() {});

        // If we are still in the initial load phase, re-center the view
        // This ensures that as nodes report their actual sizes (via MeasureSize),
        // the camera adjusts to the new layout positions.
        // BUT: Don't interrupt user-initiated focus changes
        if (_isInitialLoad &&
            (widget.viewerOptions?.enablePanAndZoom ?? true)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _centerView();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Layout calculation error: $e');
      _resetToBasicLayout();
    }
  }

  /// Reset node positions
  void _resetNodePositions(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};
    if (visited.contains(node.id)) return;
    visited.add(node.id);

    if (node != rootNode) {
      node.hasFixedPosition = false;
    }

    for (var child in node.children) {
      _resetNodePositions(child, visited: Set.from(visited));
    }
  }

  /// Calculate required canvas size
  Size _calculateRequiredCanvasSize() {
    final allNodes = _collectAllVisibleNodes(rootNode);

    if (allNodes.isEmpty) {
      return widget.minCanvasSize;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    double maxNodeWidth = 0;
    double maxNodeHeight = 0;

    for (var node in allNodes) {
      final nodeSize = widget.style.getActualNodeSize(
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
    final collapsedNodes = _collectAllCollapsedNodes(rootNode);
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
    final nodeMargin = widget.style.nodeMargin;
    // final levelSpacing = widget.style.levelSpacing;

    // Minimum margin
    final minMargin = math.max(maxNodeWidth * 0.5, 100.0);
    final extraPaddingX = math.max(minMargin, nodeMargin);
    final extraPaddingY = math.max(minMargin, nodeMargin);

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    // Canvas padding + extra padding
    final totalPaddingX = widget.canvasPadding.horizontal + (extraPaddingX * 2);
    final totalPaddingY = widget.canvasPadding.vertical + (extraPaddingY * 2);

    final requiredWidth = contentWidth + totalPaddingX;
    final requiredHeight = contentHeight + totalPaddingY;

    // Ensure minimum size
    final finalWidth = math.max(requiredWidth, widget.minCanvasSize.width);
    final finalHeight = math.max(requiredHeight, widget.minCanvasSize.height);

    // Extra margin for overflow protection
    final safetyMarginX = 100.0;
    final safetyMarginY = 150.0; // Larger value to prevent bottom overflow
    return Size(finalWidth + safetyMarginX, finalHeight + safetyMarginY);
  }

  /// Collect all visible nodes
  List<MindMapNode> _collectAllVisibleNodes(
    MindMapNode node, {
    Set<String>? visited,
  }) {
    visited ??= <String>{};
    if (visited.contains(node.id)) return [];
    visited.add(node.id);

    List<MindMapNode> nodes = [node];

    if (node.isExpanded) {
      for (var child in node.children) {
        nodes.addAll(
          _collectAllVisibleNodes(child, visited: Set.from(visited)),
        );
      }
    }

    return nodes;
  }

  /// Collect all collapsed nodes
  List<MindMapNode> _collectAllCollapsedNodes(
    MindMapNode node, {
    Set<String>? visited,
  }) {
    visited ??= <String>{};
    if (visited.contains(node.id)) return [];
    visited.add(node.id);

    List<MindMapNode> collapsedNodes = [];

    if (!node.isExpanded && node.children.isNotEmpty) {
      collapsedNodes.add(node);
      // Include all children of collapsed node
      for (var child in node.children) {
        collapsedNodes.addAll(
          _collectAllNodes(child, visited: Set.from(visited)),
        );
      }
    } else if (node.isExpanded) {
      // Recursively check children of expanded node
      for (var child in node.children) {
        collapsedNodes.addAll(
          _collectAllCollapsedNodes(child, visited: Set.from(visited)),
        );
      }
    }

    return collapsedNodes;
  }

  /// Collect all nodes regardless of expansion state
  List<MindMapNode> _collectAllNodes(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};
    if (visited.contains(node.id)) return [];
    visited.add(node.id);

    List<MindMapNode> nodes = [node];

    for (var child in node.children) {
      nodes.addAll(_collectAllNodes(child, visited: Set.from(visited)));
    }

    return nodes;
  }

  /// Estimate bounds for collapsed nodes
  Rect? _estimateCollapsedNodesBounds(List<MindMapNode> collapsedNodes) {
    if (collapsedNodes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var node in collapsedNodes) {
      final nodeSize = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      // Estimate expanded area based on current position
      // Predict expansion direction based on layout
      double expandedWidth = nodeSize.width;
      double expandedHeight = nodeSize.height;

      // Estimated size considering child count
      if (node.children.isNotEmpty) {
        final childCount = node.children.length;
        final estimatedSpacing = widget.style.levelSpacing;

        switch (widget.style.layout) {
          case MindMapLayout.right:
          case MindMapLayout.left:
          case MindMapLayout.horizontal:
            expandedWidth += estimatedSpacing;
            expandedHeight +=
                childCount * (nodeSize.height + widget.style.nodeMargin);
            break;
          case MindMapLayout.top:
          case MindMapLayout.bottom:
          case MindMapLayout.vertical:
            expandedWidth +=
                childCount * (nodeSize.width + widget.style.nodeMargin);
            expandedHeight += estimatedSpacing;
            break;
          case MindMapLayout.radial:
            final radius = estimatedSpacing * 0.8;
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

  /// Calculate root node position
  void _calculateRootPosition() {
    switch (widget.style.layout) {
      case MindMapLayout.right:
        _rootPosition = Offset(
          widget.canvasPadding.left + 100,
          _actualCanvasSize.height / 2,
        );
        break;
      case MindMapLayout.left:
        _rootPosition = Offset(
          _actualCanvasSize.width - widget.canvasPadding.right - 100,
          _actualCanvasSize.height / 2,
        );
        break;
      case MindMapLayout.top:
        _rootPosition = Offset(
          _actualCanvasSize.width / 2,
          _actualCanvasSize.height - widget.canvasPadding.bottom - 100,
        );
        break;
      case MindMapLayout.bottom:
        _rootPosition = Offset(
          _actualCanvasSize.width / 2,
          widget.canvasPadding.top + 100,
        );
        break;
      case MindMapLayout.radial:
      case MindMapLayout.horizontal:
      case MindMapLayout.vertical:
        _rootPosition = Offset(
          _actualCanvasSize.width / 2,
          _actualCanvasSize.height / 2,
        );
        break;
    }

    rootNode.position = _rootPosition;
    rootNode.targetPosition = _rootPosition;
    rootNode.hasFixedPosition = true;
  }

  /// Reset to basic layout
  void _resetToBasicLayout() {
    rootNode.position = _rootPosition;
    rootNode.targetPosition = _rootPosition;
    if (mounted) {
      setState(() {});
    }
  }

  /// Calculate subtree heights
  double _calculateSubtreeHeights(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(node.id)) {
      final nodeSize = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      return nodeSize.height + widget.style.nodeMargin;
    }
    visited.add(node.id);

    if (node.children.isEmpty) {
      final nodeSize = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      node.subtreeHeight = nodeSize.height + widget.style.nodeMargin;
      return node.subtreeHeight;
    }

    double totalChildHeight = 0;
    for (var child in node.children) {
      totalChildHeight += _calculateSubtreeHeights(
        child,
        visited: Set.from(visited),
      );
    }

    final nodeSize = widget.style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    final additionalMargin = nodeSize.height * 0.5;
    final minSpacing = widget.style.nodeMargin * 2;

    final childCountFactor = math.max(1.0, node.children.length * 0.2);
    final expandedMargin = additionalMargin * childCountFactor;

    node.subtreeHeight = math.max(
      totalChildHeight + minSpacing,
      nodeSize.height + widget.style.nodeMargin + expandedMargin,
    );

    return node.subtreeHeight;
  }

  /// Calculate subtree widths
  double _calculateSubtreeWidths(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(node.id)) {
      final nodeSize = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      return nodeSize.width + widget.style.nodeMargin;
    }
    visited.add(node.id);

    if (node.children.isEmpty) {
      final nodeSize = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );
      node.subtreeWidth = nodeSize.width + widget.style.nodeMargin;
      return node.subtreeWidth;
    }

    double totalChildWidth = 0;
    for (var child in node.children) {
      totalChildWidth += _calculateSubtreeWidths(
        child,
        visited: Set.from(visited),
      );
    }

    final nodeSize = widget.style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    final additionalMargin = nodeSize.width * 0.5;
    final minSpacing = widget.style.nodeMargin * 2;

    final childCountFactor = math.max(1.0, node.children.length * 0.2);
    final expandedMargin = additionalMargin * childCountFactor;

    node.subtreeWidth = math.max(
      totalChildWidth + minSpacing,
      nodeSize.width + widget.style.nodeMargin + expandedMargin,
    );

    return node.subtreeWidth;
  }

  /// Assign node positions
  void _assignPositions(MindMapNode parent, int level, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(parent.id) || parent.children.isEmpty) return;
    visited.add(parent.id);

    if (parent.parentDirection != null && level > 1) {
      switch (parent.parentDirection) {
        case 'top':
          _assignTopLayout(parent, level);
          break;
        case 'bottom':
          _assignBottomLayout(parent, level);
          break;
        case 'left':
          _assignLeftLayout(parent, level);
          break;
        case 'right':
          _assignRightLayout(parent, level);
          break;
        default:
          _assignLayoutByType(parent, level);
      }
    } else {
      _assignLayoutByType(parent, level);
    }

    for (var child in parent.children) {
      _assignPositions(child, level + 1, visited: Set.from(visited));
    }
  }

  /// Assign layout by type
  void _assignLayoutByType(MindMapNode parent, int level) {
    switch (widget.style.layout) {
      case MindMapLayout.right:
        _assignRightLayout(parent, level);
        break;
      case MindMapLayout.left:
        _assignLeftLayout(parent, level);
        break;
      case MindMapLayout.top:
        _assignTopLayout(parent, level);
        break;
      case MindMapLayout.bottom:
        _assignBottomLayout(parent, level);
        break;
      case MindMapLayout.radial:
        _assignRadialLayout(parent, level);
        break;
      case MindMapLayout.horizontal:
        _assignHorizontalLayout(parent, level);
        break;
      case MindMapLayout.vertical:
        _assignVerticalLayout(parent, level);
        break;
    }
  }

  /// Calculate dynamic level spacing
  double _calculateDynamicSpacing(MindMapNode parent, int level) {
    final parentSize = widget.style.getActualNodeSize(
      parent.level,
      measuredSize: parent.measuredSize,
    );

    double maxChildSize = 0;
    for (var child in parent.children) {
      final childSize = widget.style.getActualNodeSize(
        child.level,
        measuredSize: child.measuredSize,
      );
      maxChildSize = math.max(
        maxChildSize,
        math.max(childSize.width, childSize.height),
      );
    }

    final baseSpacing = widget.style.levelSpacing;
    final parentMaxSize = math.max(parentSize.width, parentSize.height);

    final nodeBasedSpacing = (parentMaxSize + maxChildSize) / 2 + 60;
    final childCountFactor = math.max(1.0, parent.children.length * 0.15);
    final levelFactor = math.max(1.0, level * 0.1);

    final dynamicSpacing = nodeBasedSpacing * childCountFactor * levelFactor;
    final minSpacing = baseSpacing + 120;

    return math.max(minSpacing, dynamicSpacing);
  }

  /// Right direction layout
  void _assignRightLayout(MindMapNode parent, int level) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final x = parent.targetPosition.dx + dynamicSpacing;
    double totalHeight = parent.children.fold(
      0.0,
      (sum, child) => sum + child.subtreeHeight,
    );

    // Apply extra gap between children
    final childGap = _calculateChildGap(parent.children);
    totalHeight += childGap * (parent.children.length - 1);

    double currentY = parent.targetPosition.dy - totalHeight / 2;

    for (var child in parent.children) {
      if (!child.hasFixedPosition) {
        final childCenterY = currentY + child.subtreeHeight / 2;
        child.targetPosition = Offset(x, childCenterY);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
        child.parentDirection = 'right';
      }
      currentY += child.subtreeHeight + childGap;
    }
  }

  /// Left direction layout
  void _assignLeftLayout(MindMapNode parent, int level) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final x = parent.targetPosition.dx - dynamicSpacing;
    double totalHeight = parent.children.fold(
      0.0,
      (sum, child) => sum + child.subtreeHeight,
    );

    // Apply extra gap between children
    final childGap = _calculateChildGap(parent.children);
    totalHeight += childGap * (parent.children.length - 1);

    double currentY = parent.targetPosition.dy - totalHeight / 2;

    for (var child in parent.children) {
      if (!child.hasFixedPosition) {
        final childCenterY = currentY + child.subtreeHeight / 2;
        child.targetPosition = Offset(x, childCenterY);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
        child.parentDirection = 'left';
      }
      currentY += child.subtreeHeight + childGap;
    }
  }

  /// Top direction layout
  void _assignTopLayout(MindMapNode parent, int level) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final y = parent.targetPosition.dy - dynamicSpacing;
    double totalWidth = parent.children.fold(
      0.0,
      (sum, child) => sum + child.subtreeWidth,
    );

    // Apply extra gap between children
    final childGap = _calculateChildGap(parent.children);
    totalWidth += childGap * (parent.children.length - 1);

    double currentX = parent.targetPosition.dx - totalWidth / 2;

    for (var child in parent.children) {
      if (!child.hasFixedPosition) {
        final childCenterX = currentX + child.subtreeWidth / 2;
        child.targetPosition = Offset(childCenterX, y);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
        child.parentDirection = 'top';
      }
      currentX += child.subtreeWidth + childGap;
    }
  }

  /// Bottom direction layout
  void _assignBottomLayout(MindMapNode parent, int level) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final y = parent.targetPosition.dy + dynamicSpacing;
    double totalWidth = parent.children.fold(
      0.0,
      (sum, child) => sum + child.subtreeWidth,
    );

    // Apply additional spacing between child nodes
    final childGap = _calculateChildGap(parent.children);
    totalWidth += childGap * (parent.children.length - 1);

    double currentX = parent.targetPosition.dx - totalWidth / 2;

    for (var child in parent.children) {
      if (!child.hasFixedPosition) {
        final childCenterX = currentX + child.subtreeWidth / 2;
        child.targetPosition = Offset(childCenterX, y);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
        child.parentDirection = 'bottom';
      }
      currentX += child.subtreeWidth + childGap;
    }
  }

  /// Radial layout
  void _assignRadialLayout(MindMapNode parent, int level) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final radius = dynamicSpacing * 0.8;
    final angleStep = (2 * math.pi) / parent.children.length;

    for (int i = 0; i < parent.children.length; i++) {
      final child = parent.children[i];
      if (!child.hasFixedPosition) {
        final angle = i * angleStep;
        final x = parent.targetPosition.dx + radius * math.cos(angle);
        final y = parent.targetPosition.dy + radius * math.sin(angle);
        child.targetPosition = Offset(x, y);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
      }
    }
  }

  /// Horizontal layout (split left-right)
  void _assignHorizontalLayout(MindMapNode parent, int level) {
    if (level == 0) {
      final leftChildren =
          parent.children.take((parent.children.length / 2).ceil()).toList();
      final rightChildren = parent.children.skip(leftChildren.length).toList();

      _assignChildrenToSide(leftChildren, parent, level, -1);
      for (var child in leftChildren) {
        child.parentDirection = 'left';
      }

      _assignChildrenToSide(rightChildren, parent, level, 1);
      for (var child in rightChildren) {
        child.parentDirection = 'right';
      }
    } else {
      if (parent.parentDirection == 'left') {
        _assignLeftLayout(parent, level);
      } else {
        _assignRightLayout(parent, level);
      }
    }
  }

  /// Vertical layout (split top-bottom)
  void _assignVerticalLayout(MindMapNode parent, int level) {
    if (level == 0) {
      final topChildren =
          parent.children.take((parent.children.length / 2).ceil()).toList();
      final bottomChildren = parent.children.skip(topChildren.length).toList();

      _assignChildrenVertically(topChildren, parent, level, -1);
      for (var child in topChildren) {
        child.parentDirection = 'top';
      }

      _assignChildrenVertically(bottomChildren, parent, level, 1);
      for (var child in bottomChildren) {
        child.parentDirection = 'bottom';
      }
    } else {
      if (parent.parentDirection == 'top') {
        _assignTopLayout(parent, level);
      } else {
        _assignBottomLayout(parent, level);
      }
    }
  }

  /// Assign children to one side
  void _assignChildrenToSide(
    List<MindMapNode> children,
    MindMapNode parent,
    int level,
    int direction,
  ) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final x = parent.targetPosition.dx + direction * dynamicSpacing;
    double totalHeight = children.fold(
      0.0,
      (sum, child) => sum + child.subtreeHeight,
    );

    // Apply additional spacing between child nodes
    final childGap = _calculateChildGap(children);
    totalHeight += childGap * (children.length - 1);

    double currentY = parent.targetPosition.dy - totalHeight / 2;

    for (var child in children) {
      if (!child.hasFixedPosition) {
        final childCenterY = currentY + child.subtreeHeight / 2;
        child.targetPosition = Offset(x, childCenterY);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
      }
      currentY += child.subtreeHeight + childGap;
    }
  }

  /// Assign children vertically
  void _assignChildrenVertically(
    List<MindMapNode> children,
    MindMapNode parent,
    int level,
    int direction,
  ) {
    final dynamicSpacing = _calculateDynamicSpacing(parent, level);
    final y = parent.targetPosition.dy + direction * dynamicSpacing;
    double totalWidth = children.fold(
      0.0,
      (sum, child) => sum + child.subtreeWidth,
    );

    // Apply additional spacing between child nodes
    final childGap = _calculateChildGap(children);
    totalWidth += childGap * (children.length - 1);

    double currentX = parent.targetPosition.dx - totalWidth / 2;

    for (var child in children) {
      if (!child.hasFixedPosition) {
        final childCenterX = currentX + child.subtreeWidth / 2;
        child.targetPosition = Offset(childCenterX, y);
        child.position = child.targetPosition;
        child.hasFixedPosition = true;
      }
      currentX += child.subtreeWidth + childGap;
    }
  }

  /// Calculate gap between child nodes
  double _calculateChildGap(List<MindMapNode> children) {
    if (children.isEmpty) return 0.0;

    // Calculate average size of child nodes
    double avgNodeSize = 0.0;
    for (var child in children) {
      final childSize = widget.style.getActualNodeSize(
        child.level,
        measuredSize: child.measuredSize,
      );
      avgNodeSize += math.max(childSize.width, childSize.height);
    }
    avgNodeSize /= children.length;

    // Default spacing + node size based spacing
    final baseGap = widget.style.nodeMargin;
    final sizeBasedGap = avgNodeSize * 0.3;
    final childCountFactor = math.min(
      2.0,
      children.length * 0.1,
    ); // Spacing increases with more children (max 2x)

    return (baseGap + sizeBasedGap) * childCountFactor;
  }

  /// Toggle node
  void toggleNode(MindMapNode node) {
    if (node.children.isEmpty || !mounted) return;

    HapticFeedback.lightImpact();
    _isTogglingNode = true;

    if (!node.isExpanded) {
      setState(() {
        node.isExpanded = true;
        try {
          _calculateCanvasAndLayout();

          // Collect all visible descendants (including children, grandchildren, etc.)
          final allVisibleDescendants =
              _collectAllVisibleNodes(node).where((n) => n != node).toList();

          // Set all descendants' positions to the parent node's position and mark as animating
          for (var child in allVisibleDescendants) {
            child.position = node.position;
            child.isAnimating = true;
          }

          // Animate all descendants to their target positions
          _animateDescendantsExpansion(node, allVisibleDescendants);
        } catch (e) {
          debugPrint('Toggle error: $e');
          node.isExpanded = false;
        }
      });
    } else {
      // Collapse: animate all visible descendants to the parent position, then collapse
      final allVisibleDescendants =
          _collectAllVisibleNodes(node).where((n) => n != node).toList();

      final startPositions = <String, Offset>{};
      for (var child in allVisibleDescendants) {
        startPositions[child.id] = child.position;
        child.isAnimating = true;
      }

      final controller = AnimationController(
        duration: widget.style.animationDuration,
        vsync: this,
      );
      _activeAnimations.add(controller);

      final animation = CurvedAnimation(
        parent: controller,
        curve: widget.style.animationCurve,
      );

      controller.addListener(() {
        if (!mounted) return;
        final progress = animation.value;
        try {
          for (var child in allVisibleDescendants) {
            if (child.isAnimating) {
              final startPos = startPositions[child.id];
              if (startPos != null) {
                // Animate from current position to parent node's position
                child.position =
                    Offset.lerp(startPos, node.position, progress)!;
              }
            }
          }
          if (mounted) setState(() {});
        } catch (e) {
          debugPrint('Collapse animation error: $e');
        }
      });

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          for (var child in allVisibleDescendants) {
            child.isAnimating = false;
            child.position = node.position;
          }
          _activeAnimations.remove(controller);
          controller.dispose();

          // Collapse after animation
          if (mounted) {
            setState(() {
              node.isExpanded = false;
              _calculateCanvasAndLayout();
            });
          }
        }
      });

      controller.forward().catchError((error) {
        debugPrint('Collapse animation start error: $error');
        _activeAnimations.remove(controller);
        controller.dispose();
        // Fallback: collapse immediately
        if (mounted) {
          setState(() {
            node.isExpanded = false;
            _calculateCanvasAndLayout();
          });
        }
      });
    }

    // Handle camera behavior on node expand based on settings
    _handleNodeExpandCamera(node);

    final originalData = _findOriginalData(node.id);
    if (originalData != null) {
      widget.onNodeExpandChanged?.call(originalData, node.isExpanded);
    }

    // Reset toggle flag after completion (in next frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isTogglingNode = false;
      }
    });
  }

  /// Handle camera behavior on node expand
  void _handleNodeExpandCamera(MindMapNode node) {
    if (!mounted || !(widget.viewerOptions?.enablePanAndZoom ?? true)) return;

    switch (widget.nodeExpandCameraBehavior) {
      case NodeExpandCameraBehavior.none:
        // No camera movement
        break;

      case NodeExpandCameraBehavior.focusClickedNode:
        // Focus on clicked node
        _focusOnNodeById(node.id);
        break;

      case NodeExpandCameraBehavior.fitExpandedChildren:
        // Adjust to show only newly expanded child nodes
        if (node.isExpanded && node.children.isNotEmpty) {
          _fitNodesToView(node.children);
        } else {
          _focusOnNodeById(node.id);
        }
        break;

      case NodeExpandCameraBehavior.fitExpandedSubtree:
        // Adjust to show entire expanded subtree
        _fitSubtreeToView(node);
        break;
    }
  }

  /// Focus camera on node by ID (using existing CameraFocus system)
  void _focusOnNodeById(String nodeId) {
    if (!mounted || !(widget.viewerOptions?.enablePanAndZoom ?? true)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _performCenterViewOnNode(nodeId);
    });
  }

  /// Perform center view on specific node
  void _performCenterViewOnNode(String nodeId) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final Size viewportSize = renderBox.size;
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    // Find target node
    final targetNode = _findNodeById(rootNode, nodeId);
    if (targetNode == null) return;

    // Node visual center
    final Offset targetPosition = targetNode.position;

    // Calculate exact center
    final double viewportCenterX = viewportSize.width / 2;
    final double viewportCenterY = viewportSize.height / 2;

    // Dynamic Correction based on manual calibration:
    double verticalOffset = widget.centerOffset?.dy ?? 0.0;
    double horizontalOffset = widget.centerOffset?.dx ?? 0.0;

    // Auto-center on screen logic
    if (widget.autoCenterOnScreen) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final globalPos = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final screenCenterY = screenHeight / 2;
        final widgetCenterY = globalPos.dy + renderBox.size.height / 2;

        // Calculate how much the widget center is offset from the screen center
        // If widget is lower (widgetCenterY > screenCenterY), we need to shift content UP (positive offset)
        // Wait, ty = Cy/s - Py - Offset.
        // If Offset is positive, ty becomes smaller (more negative), shifting content UP.
        // So Offset = WidgetCenter - ScreenCenter.
        verticalOffset += (widgetCenterY - screenCenterY);
      }
    }

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
    // Animate smoothly
    _animateToTransform(newTransform);
  }

  /// Select node
  void _selectNode(MindMapNode node) {
    setState(() {
      _selectedNodeId = node.id;
    });

    final originalData = _findOriginalData(node.id);
    if (originalData != null) {
      widget.onNodeTap?.call(originalData);
    }
  }

  /// Find original data
  MindMapData? _findOriginalData(String nodeId) {
    return _searchData(widget.data, nodeId);
  }

  MindMapData? _searchData(MindMapData data, String targetId) {
    if (data.id == targetId) return data;

    for (var child in data.children) {
      final result = _searchData(child, targetId);
      if (result != null) return result;
    }

    return null;
  }

  /// Centers the InteractiveViewer based on the camera focus option.
  void _centerView() {
    // Get the exact size in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _performCenterView();
    });
  }

  /// Perform actual center alignment (simplified for initial load only)
  void _performCenterView() {
    // Get the exact size from RenderBox
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    // Simply center on root node with initial scale
    final double scale = widget.initialScale;
    final Offset targetPosition = _rootPosition;

    _animateToCameraPosition(targetPosition, scale);
  }

  /// Calculate bounds of all nodes
  Rect? _calculateAllNodesBounds() {
    final allNodes = <MindMapNode>[];
    final allVisibleNodes = _collectAllVisibleNodes(rootNode);
    allNodes.addAll(allVisibleNodes);

    if (allNodes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in allNodes) {
      final size = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      final left = node.position.dx - size.width / 2;
      final right = node.position.dx + size.width / 2;
      final top = node.position.dy - size.height / 2;
      final bottom = node.position.dy + size.height / 2;

      minX = math.min(minX, left);
      maxX = math.max(maxX, right);
      minY = math.min(minY, top);
      maxY = math.max(maxY, bottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Find first leaf node
  MindMapNode? _findFirstLeafNode(MindMapNode node) {
    if (!node.hasChildren || !node.isExpanded) {
      return node;
    }

    for (final child in node.children) {
      final leaf = _findFirstLeafNode(child);
      if (leaf != null) return leaf;
    }

    return null;
  }

  /// Find node by ID
  MindMapNode? _findNodeById(MindMapNode node, String id) {
    if (node.id == id) return node;

    for (final child in node.children) {
      final found = _findNodeById(child, id);
      if (found != null) return found;
    }

    return null;
  }

  /// Apply transform with animation
  void _animateToTransform(Matrix4 targetTransform) {
    debugPrint('🎥 _animateToTransform called, creating AnimationController');

    // CRITICAL: Cancel all existing animations before starting a new one
    // This prevents multiple animations from fighting over the transform controller
    for (final controller in List.from(_activeAnimations)) {
      controller.stop();
      controller.dispose();
    }
    _activeAnimations.clear();
    debugPrint('🎥 Canceled ${_activeAnimations.length} previous animations');

    final Matrix4 beginTransform = _transformationController.value;
    final double beginScale = beginTransform.getMaxScaleOnAxis();
    final double endScale = targetTransform.getMaxScaleOnAxis();

    // Extract translation from matrices
    final beginTx = beginTransform.getTranslation().x;
    final beginTy = beginTransform.getTranslation().y;
    final endTx = targetTransform.getTranslation().x;
    final endTy = targetTransform.getTranslation().y;

    debugPrint('🎥 BEGIN: scale=$beginScale, tx=$beginTx, ty=$beginTy');
    debugPrint('🎥 END: scale=$endScale, tx=$endTx, ty=$endTy');
    debugPrint(
      '🎥 DELTA: scale=${endScale - beginScale}, tx=${endTx - beginTx}, ty=${endTy - beginTy}',
    );

    final AnimationController animationController = AnimationController(
      duration: widget.cameraAnimationDuration,
      vsync: this,
    );

    final Animation<Matrix4> transformAnimation = Tween<Matrix4>(
      begin: beginTransform,
      end: targetTransform,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    int updateCount = 0;
    animationController.addListener(() {
      _transformationController.value = transformAnimation.value;
      updateCount++;
      if (updateCount % 10 == 0) {
        // Log every 10th update to avoid spam
        final currentTx = transformAnimation.value.getTranslation().x;
        final currentTy = transformAnimation.value.getTranslation().y;
        debugPrint(
          '🎥 Animation update #$updateCount: tx=$currentTx, ty=$currentTy',
        );
      }
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        debugPrint(
          '🎥 Animation ${status == AnimationStatus.completed ? "completed" : "dismissed"}',
        );
        animationController.dispose();
        _activeAnimations.remove(animationController);
      }
    });

    _activeAnimations.add(animationController);
    debugPrint('🎥 Starting animation forward...');
    animationController.forward();
  }

  /// Fit specific nodes to view
  void _fitNodesToView(List<MindMapNode> nodes) {
    if (nodes.isEmpty || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) {
        return;
      }

      final Size viewportSize = renderBox.size;
      final bounds = _calculateNodesBounds(nodes);

      if (bounds == null) return;

      // 🎯 Maintain current scale (move only position)
      final double currentScale =
          _transformationController.value.getMaxScaleOnAxis();

      // Calculate center
      final Offset centerPosition = Offset(
        bounds.left + bounds.width / 2,
        bounds.top + bounds.height / 2,
      );

      final double viewportCenterX = viewportSize.width / 2;
      final double viewportCenterY = viewportSize.height / 2;

      final double tx = viewportCenterX - (centerPosition.dx * currentScale);
      final double ty = viewportCenterY - (centerPosition.dy * currentScale);

      final newTransform =
          Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(tx, ty, 0.0)
            // ignore: deprecated_member_use
            ..scale(currentScale, currentScale, 1.0);

      _animateToTransform(newTransform);
    });
  }

  /// Fit entire subtree to view
  void _fitSubtreeToView(MindMapNode rootNode) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Collect all visible nodes in subtree
      final subtreeNodes = _collectAllVisibleNodes(rootNode);
      _fitNodesToView(subtreeNodes);
    });
  }

  /// Calculate bounds of specific nodes
  Rect? _calculateNodesBounds(List<MindMapNode> nodes) {
    if (nodes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      final size = widget.style.getActualNodeSize(
        node.level,
        measuredSize: node.measuredSize,
      );

      final left = node.position.dx - size.width / 2;
      final right = node.position.dx + size.width / 2;
      final top = node.position.dy - size.height / 2;
      final bottom = node.position.dy + size.height / 2;

      minX = math.min(minX, left);
      maxX = math.max(maxX, right);
      minY = math.min(minY, top);
      maxY = math.max(maxY, bottom);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Animate all visible descendants from parent position to their target positions
  void _animateDescendantsExpansion(
    MindMapNode node,
    List<MindMapNode> descendants,
  ) {
    if (!mounted || descendants.isEmpty) return;

    final controller = AnimationController(
      duration: widget.style.animationDuration,
      vsync: this,
    );
    _activeAnimations.add(controller);

    final animation = CurvedAnimation(
      parent: controller,
      curve: widget.style.animationCurve,
    );

    final startPositions = <String, Offset>{};
    for (var child in descendants) {
      startPositions[child.id] = node.position;
    }

    controller.addListener(() {
      if (!mounted) return;
      final progress = animation.value;
      try {
        for (var child in descendants) {
          if (child.isAnimating) {
            final startPos = startPositions[child.id];
            if (startPos != null) {
              child.position =
                  Offset.lerp(startPos, child.targetPosition, progress)!;
            }
          }
        }
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Expansion animation error: $e');
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        for (var child in descendants) {
          child.isAnimating = false;
          child.position = child.targetPosition;
        }
        _activeAnimations.remove(controller);
        controller.dispose();
      }
    });

    controller.forward().catchError((error) {
      debugPrint('Expansion animation start error: $error');
      _activeAnimations.remove(controller);
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If markmap type, use dedicated widget (in development)
    // if (widget.style.mindMapType == MindMapType.markmap) {
    //   return MarkmapWidget(
    //     data: widget.data,
    //     style: widget.style,
    //     onNodeTap: widget.onNodeTap,
    //     onNodeLongPress: widget.onNodeLongPress,
    //   );
    // }

    final canvasSize =
        widget.canvasSize ??
        Size(_actualCanvasSize.width, _actualCanvasSize.height);
    final viewerOptions =
        widget.viewerOptions ?? const InteractiveViewerOptions();

    // Mind map content
    Widget content = Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: BoxDecoration(color: widget.style.backgroundColor),
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: CustomPaint(
          painter: MindMapPainter(rootNode, widget.style),
          child: Stack(children: _buildAllNodes(rootNode)),
        ),
      ),
    );

    // Wrap with RepaintBoundary if capture key exists
    if (widget.captureKey != null) {
      content = RepaintBoundary(key: widget.captureKey, child: content);
    }

    // Add scroll view only when InteractiveViewer is disabled
    if (!viewerOptions.enablePanAndZoom) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: content,
        ),
      );
    }

    final mindMapContent = content;

    if (viewerOptions.enablePanAndZoom) {
      return Stack(
        children: [
          InteractiveViewer(
            // Disable clipping so we can capture the full mind map
            clipBehavior: Clip.none,
            alignment:
                Alignment
                    .topLeft, // Ensure (0,0) matches (0,0) for correct coordinate calculations
            transformationController: _transformationController,
            constrained: viewerOptions.constrained,
            // Use a large boundary margin to allow free movement and centering of nodes near edges
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: viewerOptions.minScale,
            maxScale: viewerOptions.maxScale,
            child: mindMapContent,
          ),
          // Debug Tools
          if (widget.debugMode) ...[
            // Viewport Center Marker
            const Center(
              child: IgnorePointer(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Placeholder(color: Colors.red, strokeWidth: 2),
                ),
              ),
            ),
            // Matrix Capture Button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  // Helper to find node
                  MindMapNode? findNodeInTree(MindMapNode node, String id) {
                    if (node.id == id) return node;
                    for (var child in node.children) {
                      final found = findNodeInTree(child, id);
                      if (found != null) return found;
                    }
                    return null;
                  }

                  // Find selected node to print its size
                  MindMapNode? targetNode;
                  if (_selectedNodeId != null) {
                    targetNode = findNodeInTree(rootNode, _selectedNodeId!);
                  }

                  if (targetNode != null) {
                    // Debug info removed
                  }
                },
                child: const Icon(Icons.camera),
              ),
            ),
          ],
        ],
      );
    } else {
      return mindMapContent;
    }
  }

  /// Build all node widgets
  List<Widget> _buildAllNodes(MindMapNode node, {Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(node.id)) return [];
    visited.add(node.id);

    List<Widget> widgets = [];
    widgets.add(_buildNodeWidget(node));

    if (node.isExpanded && node.children.isNotEmpty) {
      for (var child in node.children) {
        widgets.addAll(_buildAllNodes(child, visited: Set.from(visited)));
      }
    }

    return widgets;
  }

  /// Build individual node widget
  Widget _buildNodeWidget(MindMapNode node) {
    final isSelected = _selectedNodeId == node.id;
    final isFocused = false; // focusNodeId parameter was removed

    // Determine node size: prioritize measuredSize if available, otherwise use style default
    // However, if customSize (node.size) exists, that takes highest priority
    final calculatedSize = widget.style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    // Size to use for rendering (size used in layout calculation)
    final layoutSize = node.measuredSize ?? calculatedSize;

    // Calculate node position (convert from center point to top-left coordinates)
    final nodeLeft = node.position.dx - layoutSize.width / 2;
    final nodeTop = node.position.dy - layoutSize.height / 2;

    // Screen boundary check (based on canvas size)
    // Note: We do NOT clamp positions anymore because:
    // 1. InteractiveViewer has infinite boundary margin and Clip.none, so nodes outside bounds are visible.
    // 2. Clamping causes a mismatch between node.position (used for camera focus) and rendered position.
    // final maxLeft = _actualCanvasSize.width - layoutSize.width;
    // final maxTop = _actualCanvasSize.height - layoutSize.height;

    // double constrainedLeft = nodeLeft;
    // double constrainedTop = nodeTop;

    // if (widget.style.enableAutoSizing) {
    //   constrainedLeft = constrainedLeft.clamp(0.0, maxLeft);
    //   constrainedTop = constrainedTop.clamp(0.0, maxTop);
    // }

    final constrainedLeft = nodeLeft;
    final constrainedTop = nodeTop;

    // Use style's node builder if available
    if (widget.style.nodeBuilder != null) {
      return Positioned(
        key: ValueKey('positioned_${node.id}'),
        left: constrainedLeft,
        top: constrainedTop,
        child: MeasureSize(
          onChange: (size) {
            if (node.measuredSize != size) {
              node.measuredSize = size;
              // Request layout recalculation (perform in next frame to prevent setState during build)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _calculateCanvasAndLayout();
                }
              });
            }
          },
          child: widget.style.nodeBuilder!(
            node,
            isSelected,
            () {
              if (node.hasChildren) {
                toggleNode(node);
              } else {
                _selectNode(node);
              }
            },
            () {
              final originalData = _findOriginalData(node.id);
              if (originalData != null) {
                widget.onNodeLongPress?.call(originalData);
              }
            },
            () {
              final originalData = _findOriginalData(node.id);
              if (originalData != null) {
                widget.onNodeDoubleTap?.call(originalData);
              }
            },
          ),
        ),
      );
    }

    // Use default node builder
    final nodeColor =
        ((isFocused || isSelected) ? widget.style.selectedColor : node.color) ??
        Colors.blue;
    final borderColor =
        (isFocused || isSelected)
            ? widget.style.selectionBorderColor
            : (node.borderColor ?? Colors.white);
    final borderWidth =
        (isFocused || isSelected) ? widget.style.selectionBorderWidth : 2.0;

    return Positioned(
      key: ValueKey('positioned_${node.id}'),
      left: constrainedLeft,
      top: constrainedTop,
      child: MeasureSize(
        onChange: (size) {
          if (node.measuredSize != size) {
            node.measuredSize = size;
            // Request layout recalculation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _calculateCanvasAndLayout();
              }
            });
          }
        },
        child: GestureDetector(
          onTap: () {
            if (node.hasChildren) {
              toggleNode(node);
            } else {
              _selectNode(node);
            }
          },
          onLongPress: () {
            final originalData = _findOriginalData(node.id);
            if (originalData != null) {
              widget.onNodeLongPress?.call(originalData);
            }
          },
          onDoubleTap: () {
            final originalData = _findOriginalData(node.id);
            if (originalData != null) {
              widget.onNodeDoubleTap?.call(originalData);
            }
          },
          child: Container(
            constraints:
                widget.style.enableAutoSizing
                    ? BoxConstraints(
                      minWidth: widget.style.minNodeWidth,
                      minHeight: widget.style.minNodeHeight,
                      // No max constraints when auto-sizing to allow content to determine size
                    )
                    : BoxConstraints(
                      minWidth: widget.style.minNodeWidth,
                      minHeight: widget.style.minNodeHeight,
                      maxWidth: widget.style.maxNodeWidth,
                    ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: ShapeDecoration(
                color: nodeColor,
                shape: _getShapeBorder(
                  widget.style.nodeShape,
                  borderColor,
                  borderWidth,
                ),
                shadows:
                    widget.style.enableNodeShadow
                        ? [
                          BoxShadow(
                            color: widget.style.nodeShadowColor,
                            blurRadius: widget.style.nodeShadowBlurRadius,
                            spreadRadius: widget.style.nodeShadowSpreadRadius,
                            offset: widget.style.nodeShadowOffset,
                          ),
                        ]
                        : null,
              ),
              child: node.content,
            ),
          ),
        ),
      ),
    );
  }

  ShapeBorder _getShapeBorder(
    NodeShape shape,
    Color borderColor,
    double borderWidth,
  ) {
    switch (shape) {
      case NodeShape.circle:
        return CircleBorder(
          side: BorderSide(color: borderColor, width: borderWidth),
        );
      case NodeShape.rectangle:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: borderColor, width: borderWidth),
        );
      case NodeShape.roundedRectangle:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: borderWidth),
        );
      case NodeShape.ellipse:
        return StadiumBorder(
          side: BorderSide(color: borderColor, width: borderWidth),
        );
      case NodeShape.diamond:
        return BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: borderColor, width: borderWidth),
        );
      case NodeShape.hexagon:
        return BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: borderWidth),
        );
    }
  }

  // ============================================================================
  // PUBLIC CAMERA CONTROL METHODS
  // ============================================================================

  /// Build list of all focusable nodes in depth-first order
  void _buildFocusableNodesList() {
    _focusableNodes.clear();
    _addNodeToFocusableList(rootNode);
  }

  void _addNodeToFocusableList(MindMapNode node) {
    _focusableNodes.add(node);
    for (final child in node.children) {
      if (child.isExpanded) {
        // Only add expanded (visible) children
        _addNodeToFocusableList(child);
      }
    }
  }

  /// Zoom out to fit all nodes in the viewport
  void zoomToFitAll() {
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Size viewportSize = renderBox.size;
    final bounds = _calculateAllNodesBounds();

    if (bounds == null) return;

    // Calculate scale to fit all nodes with margin
    const margin = 50.0;
    final scaleX = (viewportSize.width - margin * 2) / bounds.width;
    final scaleY = (viewportSize.height - margin * 2) / bounds.height;
    final scale = math.min(scaleX, scaleY).clamp(0.1, 2.5);

    // Center of all nodes
    final targetPosition = Offset(
      bounds.left + bounds.width / 2,
      bounds.top + bounds.height / 2,
    );

    _animateToCameraPosition(targetPosition, scale);
  }

  /// Focus on the next node in the sequence
  void focusNext() {
    if (!mounted) return;

    _buildFocusableNodesList();
    if (_focusableNodes.isEmpty) return;

    // Move to next node (wrap around)
    _currentFocusedNodeIndex =
        (_currentFocusedNodeIndex + 1) % _focusableNodes.length;
    final node = _focusableNodes[_currentFocusedNodeIndex];

    _focusOnNodeCenter(node);
  }

  /// Focus on the previous node in the sequence
  void focusPrevious() {
    if (!mounted) return;

    _buildFocusableNodesList();
    if (_focusableNodes.isEmpty) return;

    // Move to previous node (wrap around)
    _currentFocusedNodeIndex =
        (_currentFocusedNodeIndex - 1 + _focusableNodes.length) %
        _focusableNodes.length;
    final node = _focusableNodes[_currentFocusedNodeIndex];

    _focusOnNodeCenter(node);
  }

  /// Focus camera on the center of a specific node, preserving current zoom level
  void _focusOnNodeCenter(MindMapNode node) {
    // Compute target scale to fit the node within the viewport
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final Size viewportSize = renderBox.size;

    // Determine node size using style (fallback to measuredSize)
    final nodeSize = widget.style.getActualNodeSize(
      node.level,
      measuredSize: node.measuredSize,
    );

    // Calculate scale to fit node (no margins)
    double scaleX = viewportSize.width / nodeSize.width;
    double scaleY = viewportSize.height / nodeSize.height;
    double targetScale = math.min(scaleX, scaleY);
    targetScale = targetScale.clamp(
      widget.viewerOptions?.minScale ?? 0.1,
      widget.viewerOptions?.maxScale ?? 2.5,
    );

    // Animate to node center with calculated scale, ignoring auto offsets
    _animateToCameraPositionNoOffset(node.position, targetScale);
  }

  /// Animate camera to a specific position and scale, ignoring autoCenterOnScreen offsets
  void _animateToCameraPositionNoOffset(Offset targetPosition, double scale) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Size viewportSize = renderBox.size;
    final double viewportCenterX = viewportSize.width / 2;
    final double viewportCenterY = viewportSize.height / 2;

    // No offsets applied
    final double tx = viewportCenterX / scale - targetPosition.dx;
    final double ty = viewportCenterY / scale - targetPosition.dy;

    final newTransform =
        Matrix4.identity()
          ..scale(scale, scale, 1.0)
          ..translate(tx, ty, 0.0);

    if (widget.cameraAnimationDuration.inMilliseconds > 0) {
      _animateToTransform(newTransform);
    } else {
      _transformationController.value = newTransform;
    }
  }

  /// Animate camera to a specific position and scale
  void _animateToCameraPosition(Offset targetPosition, double scale) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Size viewportSize = renderBox.size;
    final double viewportCenterX = viewportSize.width / 2;
    final double viewportCenterY = viewportSize.height / 2;

    // Apply offsets
    double verticalOffset = widget.centerOffset?.dy ?? 0.0;
    double horizontalOffset = widget.centerOffset?.dx ?? 0.0;

    if (widget.autoCenterOnScreen) {
      final globalPos = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      final screenCenterY = screenHeight / 2;
      final widgetCenterY = globalPos.dy + renderBox.size.height / 2;
      final autoOffset = widgetCenterY - screenCenterY;
      verticalOffset += autoOffset;

      debugPrint('🎯 autoCenterOnScreen calculation:');
      debugPrint('   - globalPos.dy: ${globalPos.dy}');
      debugPrint('   - renderBox.size.height: ${renderBox.size.height}');
      debugPrint('   - widgetCenterY: $widgetCenterY');
      debugPrint('   - screenHeight: $screenHeight');
      debugPrint('   - screenCenterY: $screenCenterY');
      debugPrint('   - autoOffset: $autoOffset');
      debugPrint('   - total verticalOffset: $verticalOffset');
    }

    // Calculate translation to center the target position
    final double tx =
        viewportCenterX / scale - targetPosition.dx - horizontalOffset;
    final double ty =
        viewportCenterY / scale - targetPosition.dy - verticalOffset;

    debugPrint('🎯 Final camera calculation:');
    debugPrint('   - targetPosition: $targetPosition');
    debugPrint('   - viewportCenter: ($viewportCenterX, $viewportCenterY)');
    debugPrint('   - scale: $scale');
    debugPrint('   - offsets: h=$horizontalOffset, v=$verticalOffset');
    debugPrint('   - translation: tx=$tx, ty=$ty');

    final newTransform =
        Matrix4.identity()
          ..scale(scale, scale, 1.0)
          ..translate(tx, ty, 0.0);

    // Animate to new transform
    if (widget.cameraAnimationDuration.inMilliseconds > 0) {
      _animateToTransform(newTransform);
    } else {
      _transformationController.value = newTransform;
    }
  }

  // ============================================================================
  // PUBLIC GETTERS FOR DEBUGGING
  // ============================================================================

  /// Get the transformation controller (for debugging)
  TransformationController get transformationController =>
      _transformationController;

  /// Get the list of focusable nodes (for debugging)
  List<MindMapNode> get focusableNodes => _focusableNodes;

  /// Get the current focused node index (for debugging)
  int get currentFocusedNodeIndex => _currentFocusedNodeIndex;
}
