import 'package:flutter/material.dart';
import 'package:reactive_mind_map/reactive_mind_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Focus 테스트',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  CameraFocus currentFocus = CameraFocus.rootNode;
  String? targetNodeId;
  String lastAction = '시작';
  NodeExpandCameraBehavior expandBehavior = NodeExpandCameraBehavior.none;

  // 간단한 테스트 데이터
  late MindMapData mindMapData;

  @override
  void initState() {
    super.initState();

    mindMapData = MindMapData(
      id: 'root',
      content: const Text(
        '🎯 메인',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      children: [
        MindMapData(
          id: 'node1',
          content: const Text(
            'Testing this node to see if it can hangle long text or does it switch it to three dots so this is the very long text to Testing this node to see if it can hangle long text or does it switch it to three dots so this is the very long text\n\n to Testing this node to see if it can hangle long text or does it switch it  to Testing this node to see if it to three dots so this is the very long text to And this is the last line',
          ),
          borderColor: Colors.green,
          children: [
            MindMapData(
              id: 'sub1',
              borderColor: Colors.purple,
              content: const Text('Sub 1'),
            ),
            MindMapData(
              id: 'sub2',
              content: const Text('Test test test', textAlign: TextAlign.right),
            ),
          ],
        ),
        MindMapData(id: 'node2', content: const Text('🎨 노드2')),
        MindMapData(id: 'node3', content: const Text('🔧 노드3')),
        MindMapData(
          id: 'node4',
          content: const Text('🚀 노드4'),
          children: [MindMapData(id: 'final', content: const Text('마지막'))],
        ),
      ],
    );
  }

  void _editNode(MindMapData node) {
    // Example implementation of edit node
    setState(() {
      mindMapData = MindMapData.updateNodeInTree(
        mindMapData,
        node.id,
        (n) => n.copyWith(content: const Text('Edited Node')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카메라 포커스 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 간단한 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildButton(
                  '🎯 루트',
                  () => _focusToNode(CameraFocus.rootNode, null),
                ),
                _buildButton(
                  '🔍 전체보기',
                  () => _focusToNode(CameraFocus.fitAll, null),
                ),
                _buildButton(
                  '📝 노드1',
                  () => _focusToNode(CameraFocus.custom, 'node1'),
                ),
                _buildButton(
                  '서브1',
                  () => _focusToNode(CameraFocus.custom, 'sub1'),
                ),
                _buildButton(
                  '마지막',
                  () => _focusToNode(CameraFocus.custom, 'final'),
                ),
                _buildButton(
                  '🍃 첫리프',
                  () => _focusToNode(CameraFocus.firstLeaf, null),
                ),
                // Forward/Backward focus buttons
                _buildButton('⬅️ 이전', _focusPreviousNode),
                _buildButton('다음 ➡️', _focusNextNode),
              ],
            ),
          ),

          // 🆕 노드 확장 동작 선택
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📂 노드 확장 시 카메라 동작:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    _buildExpandBehaviorButton(
                      '❌ 이동없음',
                      NodeExpandCameraBehavior.none,
                    ),
                    _buildExpandBehaviorButton(
                      '🎯 클릭노드',
                      NodeExpandCameraBehavior.focusClickedNode,
                    ),
                    _buildExpandBehaviorButton(
                      '👶 자식들만',
                      NodeExpandCameraBehavior.fitExpandedChildren,
                    ),
                    _buildExpandBehaviorButton(
                      '🌳 전체트리',
                      NodeExpandCameraBehavior.fitExpandedSubtree,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 상태 표시
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('현재 포커스: ${_getFocusName()}'),
                Text('마지막 동작: $lastAction'),
                Text('확장 동작: ${_getExpandBehaviorName()}'),
              ],
            ),
          ),

          // 마인드맵
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MindMapWidget(
                  data: mindMapData,
                  style: MindMapStyle(
                    backgroundColor: const Color(0xFFF8F9FA),
                    selectedColor: Colors.red,
                    defaultNodeColors: const [
                      Color(0xFF2196F3),
                      Color(0xFFFF9800),
                      Color(0xFFE91E63),
                    ],
                    levelSpacing: 120,
                    nodeMargin: 15,
                  ),
                  cameraFocus: currentFocus,
                  focusNodeId: targetNodeId,
                  focusAnimation: const Duration(), // 더 긴 애니메이션
                  isNodesCollapsed: false, // 모든 노드 펼쳐져 있음
                  nodeExpandCameraBehavior: expandBehavior,
                  onNodeTap: (node) {
                    debugPrint('탭된 노드: ${node.description} (${node.id})');
                    setState(() {
                      lastAction = '노드 탭: ${node.description}';
                      // Example of editing the tapped node
                      _editNode(node);
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  void _focusToNode(CameraFocus focus, String? nodeId) {
    setState(() {
      currentFocus = focus;
      targetNodeId = nodeId;
      lastAction =
          '${_getFocusName()} ${nodeId != null ? '→ $nodeId' : ''}로 이동';
    });
  }

  String _getFocusName() {
    switch (currentFocus) {
      case CameraFocus.rootNode:
        return '루트';
      case CameraFocus.fitAll:
        return '전체보기';
      case CameraFocus.custom:
        return '커스텀';
      case CameraFocus.firstLeaf:
        return '첫리프';
      case CameraFocus.center:
        return '중앙';
    }
  }

  Widget _buildExpandBehaviorButton(
    String text,
    NodeExpandCameraBehavior behavior,
  ) {
    return ElevatedButton(
      onPressed: () => setState(() => expandBehavior = behavior),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  String _getExpandBehaviorName() {
    switch (expandBehavior) {
      case NodeExpandCameraBehavior.none:
        return '❌ 이동없음';
      case NodeExpandCameraBehavior.focusClickedNode:
        return '🎯 클릭노드';
      case NodeExpandCameraBehavior.fitExpandedChildren:
        return '👶 자식들만';
      case NodeExpandCameraBehavior.fitExpandedSubtree:
        return '🌳 전체트리';
    }
  }

  void _focusNextNode() {
    final flatNodes = mindMapData.flatten();
    if (flatNodes.isEmpty) return;
    int currentIdx = flatNodes.indexWhere((n) => n.id == targetNodeId);
    int nextIdx = (currentIdx + 1) % flatNodes.length;
    final nextNode = flatNodes[nextIdx];
    setState(() {
      mindMapData = MindMapData.updateNodeInTree(
        mindMapData,
        nextNode.id,
        (node) => node.copyWith(color: Colors.blue),
      );
      currentFocus = CameraFocus.custom;
      targetNodeId = nextNode.id;
      lastAction = '다음 노드로 이동: ${nextNode.description}';
    });
  }

  void _focusPreviousNode() {
    final flatNodes = mindMapData.flatten();
    if (flatNodes.isEmpty) return;
    int currentIdx = flatNodes.indexWhere((n) => n.id == targetNodeId);
    int prevIdx = (currentIdx - 1);
    if (prevIdx < 0) prevIdx = flatNodes.length - 1;
    final prevNode = flatNodes[prevIdx];
    setState(() {
      currentFocus = CameraFocus.custom;
      targetNodeId = prevNode.id;
      lastAction = '이전 노드로 이동: ${prevNode.description}';
    });
  }
}
