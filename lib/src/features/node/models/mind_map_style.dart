import 'package:flutter/material.dart';
import '../../../core/enums/mind_map_layout.dart';
import '../../../core/enums/node_shape.dart';
import '../../../core/enums/mind_map_type.dart';
import 'mind_map_node.dart';

/// Class that defines the overall style of the mind map
class MindMapStyle {
  /// Mind map type
  final MindMapType mindMapType;

  /// Mind map layout direction
  final MindMapLayout layout;

  /// Node shape
  final NodeShape nodeShape;

  /// Background color
  final Color backgroundColor;

  /// Horizontal spacing between nodes
  final double levelSpacing;

  /// Vertical margin between nodes
  final double nodeMargin;

  /// Connection line color
  final Color connectionColor;

  /// Connection line thickness
  final double connectionWidth;

  /// Connection line style (straight or curved)
  final bool useCustomCurve;

  /// Default node colors
  final List<Color> defaultNodeColors;

  /// Root node size
  final double rootNodeSize;

  /// Primary child node size
  final double primaryNodeSize;

  /// Leaf node size
  final double leafNodeSize;

  /// Border color when node is selected
  final Color selectionBorderColor;

  /// Border thickness when node is selected
  final double selectionBorderWidth;

  /// Color when node is selected
  final Color? selectedColor;

  /// Node animation duration
  final Duration animationDuration;

  /// Node animation curve
  final Curve animationCurve;

  /// Whether node shadow is enabled
  final bool enableNodeShadow;

  /// Node shadow color
  final Color nodeShadowColor;

  /// Node shadow blur radius
  final double nodeShadowBlurRadius;

  /// Node shadow spread radius
  final double nodeShadowSpreadRadius;

  /// Node shadow offset
  final Offset nodeShadowOffset;

  /// Whether auto-sizing for nodes is enabled
  final bool enableAutoSizing;

  /// Minimum node width
  final double minNodeWidth;

  /// Maximum node width
  final double maxNodeWidth;

  /// Minimum node height
  final double minNodeHeight;

  /// Text padding
  final EdgeInsets textPadding;

  /// Maximum width for custom nodes
  final double maxCustomNodeWidth;

  /// Maximum height for custom nodes
  final double maxCustomNodeHeight;

  /// Minimum width for custom nodes
  final double minCustomNodeWidth;

  /// Minimum height for custom nodes
  final double minCustomNodeHeight;

  /// Whether to auto-adjust custom node size
  final bool enableCustomNodeAutoSizing;

  /// Node builder function
  final Widget Function(
    MindMapNode,
    bool,
    VoidCallback,
    VoidCallback,
    VoidCallback,
  )?
  nodeBuilder;

  const MindMapStyle({
    this.mindMapType = MindMapType.default_,
    this.layout = MindMapLayout.right,
    this.nodeShape = NodeShape.roundedRectangle,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.levelSpacing = 240.0,
    this.nodeMargin = 40.0,
    this.connectionColor = Colors.grey,
    this.connectionWidth = 2.5,
    this.useCustomCurve = true,
    this.defaultNodeColors = const [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFFF59E0B),
      Color(0xFF7C2D12),
      Color(0xFF6B21A8),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
    ],
    this.rootNodeSize = 80.0,
    this.primaryNodeSize = 60.0,
    this.leafNodeSize = 45.0,
    this.selectionBorderColor = Colors.yellow,
    this.selectionBorderWidth = 3.0,
    this.selectedColor,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeOutCubic,
    this.enableNodeShadow = true,
    this.nodeShadowColor = Colors.black26,
    this.nodeShadowBlurRadius = 8.0,
    this.nodeShadowSpreadRadius = 2.0,
    this.nodeShadowOffset = const Offset(0, 4),
    this.enableAutoSizing = true,
    this.minNodeWidth = 80.0,
    this.maxNodeWidth = 200.0,
    this.minNodeHeight = 40.0,
    this.textPadding = const EdgeInsets.all(12.0),
    this.maxCustomNodeWidth = 200.0,
    this.maxCustomNodeHeight = 150.0,
    this.minCustomNodeWidth = 60.0,
    this.minCustomNodeHeight = 40.0,
    this.enableCustomNodeAutoSizing = true,
    this.nodeBuilder,
  });

  /// copyWith method for style copying
  MindMapStyle copyWith({
    MindMapType? mindMapType,
    MindMapLayout? layout,
    NodeShape? nodeShape,
    Color? backgroundColor,
    double? levelSpacing,
    double? nodeMargin,
    Color? connectionColor,
    double? connectionWidth,
    bool? useCustomCurve,
    List<Color>? defaultNodeColors,
    double? rootNodeSize,
    double? primaryNodeSize,
    double? leafNodeSize,
    Color? selectionBorderColor,
    double? selectionBorderWidth,
    Color? selectedColor,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableNodeShadow,
    Color? nodeShadowColor,
    double? nodeShadowBlurRadius,
    double? nodeShadowSpreadRadius,
    Offset? nodeShadowOffset,
    bool? enableAutoSizing,
    double? minNodeWidth,
    double? maxNodeWidth,
    double? minNodeHeight,
    EdgeInsets? textPadding,
    double? maxCustomNodeWidth,
    double? maxCustomNodeHeight,
    double? minCustomNodeWidth,
    double? minCustomNodeHeight,
    bool? enableCustomNodeAutoSizing,
    Widget Function(
      MindMapNode,
      bool,
      VoidCallback,
      VoidCallback,
      VoidCallback,
    )?
    nodeBuilder,
  }) {
    return MindMapStyle(
      mindMapType: mindMapType ?? this.mindMapType,
      layout: layout ?? this.layout,
      nodeShape: nodeShape ?? this.nodeShape,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      levelSpacing: levelSpacing ?? this.levelSpacing,
      nodeMargin: nodeMargin ?? this.nodeMargin,
      connectionColor: connectionColor ?? this.connectionColor,
      connectionWidth: connectionWidth ?? this.connectionWidth,
      useCustomCurve: useCustomCurve ?? this.useCustomCurve,
      defaultNodeColors: defaultNodeColors ?? this.defaultNodeColors,
      rootNodeSize: rootNodeSize ?? this.rootNodeSize,
      primaryNodeSize: primaryNodeSize ?? this.primaryNodeSize,
      leafNodeSize: leafNodeSize ?? this.leafNodeSize,
      selectionBorderColor: selectionBorderColor ?? this.selectionBorderColor,
      selectionBorderWidth: selectionBorderWidth ?? this.selectionBorderWidth,
      selectedColor: selectedColor ?? this.selectedColor,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      enableNodeShadow: enableNodeShadow ?? this.enableNodeShadow,
      nodeShadowColor: nodeShadowColor ?? this.nodeShadowColor,
      nodeShadowBlurRadius: nodeShadowBlurRadius ?? this.nodeShadowBlurRadius,
      nodeShadowSpreadRadius:
          nodeShadowSpreadRadius ?? this.nodeShadowSpreadRadius,
      nodeShadowOffset: nodeShadowOffset ?? this.nodeShadowOffset,
      enableAutoSizing: enableAutoSizing ?? this.enableAutoSizing,
      minNodeWidth: minNodeWidth ?? this.minNodeWidth,
      maxNodeWidth: maxNodeWidth ?? this.maxNodeWidth,
      minNodeHeight: minNodeHeight ?? this.minNodeHeight,
      textPadding: textPadding ?? this.textPadding,
      maxCustomNodeWidth: maxCustomNodeWidth ?? this.maxCustomNodeWidth,
      maxCustomNodeHeight: maxCustomNodeHeight ?? this.maxCustomNodeHeight,
      minCustomNodeWidth: minCustomNodeWidth ?? this.minCustomNodeWidth,
      minCustomNodeHeight: minCustomNodeHeight ?? this.minCustomNodeHeight,
      enableCustomNodeAutoSizing:
          enableCustomNodeAutoSizing ?? this.enableCustomNodeAutoSizing,
      nodeBuilder: nodeBuilder ?? this.nodeBuilder,
    );
  }

  /// Returns size based on node level
  double getNodeSize(int level) {
    if (level == 0) return rootNodeSize;
    if (level == 1) return primaryNodeSize;
    return leafNodeSize;
  }

  /// Adjust custom node size within limits
  Size adjustCustomNodeSize(Size originalSize) {
    if (!enableCustomNodeAutoSizing) {
      return originalSize;
    }

    double adjustedWidth = originalSize.width;
    double adjustedHeight = originalSize.height;

    // 최소/최대 크기 제한 적용
    adjustedWidth = adjustedWidth.clamp(minCustomNodeWidth, maxCustomNodeWidth);
    adjustedHeight = adjustedHeight.clamp(
      minCustomNodeHeight,
      maxCustomNodeHeight,
    );

    return Size(adjustedWidth, adjustedHeight);
  }

  /// Returns default color based on node level
  Color getDefaultNodeColor(int level) {
    return defaultNodeColors[level % defaultNodeColors.length];
  }

  /// Returns text size based on node level
  double getTextSize(int level) {
    if (level == 0) return 14.0;
    if (level == 1) return 12.0;
    return 10.0;
  }

  /// Returns actual node size
  ///
  /// If [measuredSize] is provided and [enableAutoSizing] is true, uses the measured size
  /// with min/max constraints. Otherwise uses level-based default sizing.
  Size getActualNodeSize(int level, {Size? measuredSize}) {
    // If we have a measured size and auto-sizing is enabled, use it
    if (enableAutoSizing && measuredSize != null) {
      return Size(
        measuredSize.width.clamp(minNodeWidth, maxNodeWidth),
        measuredSize.height.clamp(minNodeHeight, double.infinity),
      );
    }

    // Otherwise use level-based default sizing
    final levelSize = getNodeSize(level);
    return Size(
      levelSize.clamp(minNodeWidth, maxNodeWidth),
      (levelSize * 0.6).clamp(minNodeHeight, double.infinity),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MindMapStyle) return false;

    return mindMapType == other.mindMapType &&
        layout == other.layout &&
        nodeShape == other.nodeShape &&
        backgroundColor == other.backgroundColor &&
        levelSpacing == other.levelSpacing &&
        nodeMargin == other.nodeMargin &&
        connectionColor == other.connectionColor &&
        connectionWidth == other.connectionWidth &&
        useCustomCurve == other.useCustomCurve &&
        _listEquals(defaultNodeColors, other.defaultNodeColors) &&
        rootNodeSize == other.rootNodeSize &&
        primaryNodeSize == other.primaryNodeSize &&
        leafNodeSize == other.leafNodeSize &&
        selectionBorderColor == other.selectionBorderColor &&
        selectionBorderWidth == other.selectionBorderWidth &&
        selectedColor == other.selectedColor &&
        animationDuration == other.animationDuration &&
        animationCurve == other.animationCurve &&
        enableNodeShadow == other.enableNodeShadow &&
        nodeShadowColor == other.nodeShadowColor &&
        nodeShadowBlurRadius == other.nodeShadowBlurRadius &&
        nodeShadowSpreadRadius == other.nodeShadowSpreadRadius &&
        nodeShadowOffset == other.nodeShadowOffset &&
        enableAutoSizing == other.enableAutoSizing &&
        minNodeWidth == other.minNodeWidth &&
        maxNodeWidth == other.maxNodeWidth &&
        minNodeHeight == other.minNodeHeight &&
        textPadding == other.textPadding &&
        maxCustomNodeWidth == other.maxCustomNodeWidth &&
        maxCustomNodeHeight == other.maxCustomNodeHeight &&
        minCustomNodeWidth == other.minCustomNodeWidth &&
        minCustomNodeHeight == other.minCustomNodeHeight &&
        enableCustomNodeAutoSizing == other.enableCustomNodeAutoSizing &&
        nodeBuilder == other.nodeBuilder;
  }

  @override
  int get hashCode {
    return Object.hash(
          mindMapType,
          layout,
          nodeShape,
          backgroundColor,
          levelSpacing,
          nodeMargin,
          connectionColor,
          connectionWidth,
          useCustomCurve,
          Object.hashAll(defaultNodeColors),
          rootNodeSize,
          primaryNodeSize,
          leafNodeSize,
          selectionBorderColor,
          selectionBorderWidth,
          selectedColor,
          animationDuration,
          animationCurve,
          enableNodeShadow,
          nodeShadowColor,
        ) ^
        Object.hash(
          nodeShadowBlurRadius,
          nodeShadowSpreadRadius,
          nodeShadowOffset,
          enableAutoSizing,
          minNodeWidth,
          maxNodeWidth,
          minNodeHeight,
          textPadding,
          maxCustomNodeWidth,
          maxCustomNodeHeight,
          minCustomNodeWidth,
          minCustomNodeHeight,
          enableCustomNodeAutoSizing,
          nodeBuilder,
        );
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
