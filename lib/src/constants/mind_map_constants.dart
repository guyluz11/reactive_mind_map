import 'package:flutter/material.dart';

/// Constants used throughout the mind map package
class MindMapConstants {
  // Prevent instantiation
  MindMapConstants._();

  // Default canvas sizes
  static const defaultMinCanvasWidth = 1200.0;
  static const defaultMinCanvasHeight = 800.0;

  // Default padding and margins
  static const defaultCanvasPadding = 300.0;
  static const defaultSafetyMarginX = 100.0;
  static const defaultSafetyMarginY = 150.0;

  // Camera and viewport
  static const verticalOffsetCorrection = 60.0;
  static const defaultInitialScale = 1.0;

  // Layout spacing
  static const defaultRootNodeOffset = 100.0;
  static const defaultLevelSpacing = 200.0;
  static const defaultNodeMargin = 40.0;

  // Animation
  static const defaultAnimationDuration = Duration(milliseconds: 300);
  static const defaultAnimationThreshold = 0.3;
  static const defaultAnimationHighThreshold = 0.8;

  // Node sizing
  static const defaultMinNodeWidth = 80.0;
  static const defaultMaxNodeWidth = 300.0;
  static const defaultMinNodeHeight = 40.0;
  static const defaultRootNodeSize = 120.0;
  static const defaultPrimaryNodeSize = 100.0;
  static const defaultLeafNodeSize = 80.0;

  // Connection lines
  static const defaultConnectionWidth = 2.0;
  static const defaultControlDistanceMultiplier = 0.3;

  // Spacing calculations
  static const minMarginMultiplier = 0.5;
  static const minMarginFallback = 100.0;
  static const childGapSizeMultiplier = 0.3;
  static const childCountFactorMultiplier = 0.1;
  static const maxChildCountFactor = 2.0;

  // Layout calculation factors
  static const additionalMarginMultiplier = 0.5;
  static const minSpacingMultiplier = 2.0;
  static const childCountSpacingMultiplier = 0.2;
  static const levelSpacingMultiplier = 0.1;
  static const nodeBasedSpacingOffset = 60.0;
  static const minDynamicSpacing = 120.0;

  // Radial layout
  static const radialLayoutRadiusMultiplier = 0.8;

  // Shadow defaults
  static const defaultShadowBlurRadius = 4.0;
  static const defaultShadowSpreadRadius = 0.0;
  static const defaultShadowOffset = Offset(0, 2);

  // Interactive viewer
  static const defaultMinScale = 0.1;
  static const defaultMaxScale = 3.0;
  static const infiniteBoundary = double.infinity;

  // Debug
  static const debugMarkerSize = 20.0;
}
