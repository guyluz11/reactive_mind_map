/// Camera focus options
enum CameraFocus {
  /// Focus on root node
  rootNode,

  /// Focus on canvas center
  center,

  /// Focus on all nodes
  allNodes,

  /// Focus on first leaf node
  firstLeaf,

  /// Focus on custom node
  custom,

  /// Fit all nodes in viewport with margins
  fitAllNodes,
}

/// Camera behavior when expanding nodes
enum NodeExpandCameraBehavior {
  /// No camera movement
  none,

  /// Focus on clicked node
  focusClickedNode,

  /// Fit all newly expanded children
  fitExpandedChildren,

  /// Fit entire expanded subtree
  fitExpandedSubtree,
}
