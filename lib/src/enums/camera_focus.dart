/// 마인드맵/// 카메라 포커스 옵션 / Camera focus options
enum CameraFocus {
  /// 루트 노드에 포커스 / Focus on root node
  rootNode,

  /// 캔버스 중앙에 포커스 / Focus on canvas center
  center,

  /// 모든 노드가 보이도록 포커스 / Focus on all nodes
  allNodes,

  /// 첫 번째 리프 노드에 포커스 / Focus on first leaf node
  firstLeaf,

  /// 커스텀 노드에 포커스 / Focus on custom node
  custom,

  /// 모든 노드를 화면에 맞춤 (마진 포함) / Fit all nodes in viewport with margins
  fitAllNodes,
}

/// 노드 확장 시 카메라 동작 옵션 / Camera behavior when expanding nodes
enum NodeExpandCameraBehavior {
  /// 카메라 이동 없음 / No camera movement
  none,

  /// 클릭한 노드로 포커스 / Focus on clicked node
  focusClickedNode,

  /// 새로 펼쳐진 자식 노드들을 모두 보이도록 조정 / Fit all newly expanded children
  fitExpandedChildren,

  /// 펼쳐진 전체 서브트리를 보이도록 조정 / Fit entire expanded subtree
  fitExpandedSubtree,
}
