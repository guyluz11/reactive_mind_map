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
      title: 'Camera Focus Test',
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
  String lastAction = 'Start';
  NodeExpandCameraBehavior expandBehavior = NodeExpandCameraBehavior.none;

  // Simple test data
  late MindMapData mindMapData;

  @override
  void initState() {
    super.initState();

    mindMapData = MindMapData(
      id: 'root',
      content: const Text(
        '🎯 Main',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      children: [
        MindMapData(
          id: 'node1',
          content: const Text('Tests das das d"'),
          borderColor: Colors.green,
          children: [
            MindMapData(
              id: 'sub1',
              borderColor: Colors.purple,
              content: const Text('Sub 1'),
            ),
            MindMapData(
              id: 'sub2',
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Container(
                  margin: const EdgeInsets.all(50 / 2),

                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter your name',
                      hintText: 'John Doe',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      debugPrint('User typed: $value');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        MindMapData(id: 'node2', content: const Text('🎨 Node 2')),
        MindMapData(id: 'node3', content: const Text('🔧 Node 3')),
        MindMapData(
          id: 'node4',
          content: const Text('🚀 Node 4'),
          children: [MindMapData(id: 'final', content: const Text('Final'))],
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
        title: const Text('Camera Focus Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Simple buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildButton(
                  '🎯 Root',
                  () => _focusToNode(CameraFocus.rootNode, null),
                ),
                _buildButton(
                  '🔍 Fit All',
                  () => _focusToNode(CameraFocus.allNodes, null),
                ),
                _buildButton(
                  '📝 Node 1',
                  () => _focusToNode(CameraFocus.custom, 'node1'),
                ),
                _buildButton(
                  '서브1',
                  () => _focusToNode(CameraFocus.custom, 'sub1'),
                ),
                _buildButton(
                  'Final',
                  () => _focusToNode(CameraFocus.custom, 'final'),
                ),
                _buildButton(
                  '🍃 First Leaf',
                  () => _focusToNode(CameraFocus.firstLeaf, null),
                ),
                // Forward/Backward focus buttons
                _buildButton('⬅️ Prev', _focusPreviousNode),
                _buildButton('Next ➡️', _focusNextNode),
              ],
            ),
          ),

          // 🆕 Select node expand behavior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📂 Camera Behavior on Expand:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    _buildExpandBehaviorButton(
                      '❌ None',
                      NodeExpandCameraBehavior.none,
                    ),
                    _buildExpandBehaviorButton(
                      '🎯 Clicked Node',
                      NodeExpandCameraBehavior.focusClickedNode,
                    ),
                    _buildExpandBehaviorButton(
                      '👶 Children Only',
                      NodeExpandCameraBehavior.fitExpandedChildren,
                    ),
                    _buildExpandBehaviorButton(
                      '🌳 Subtree',
                      NodeExpandCameraBehavior.fitExpandedSubtree,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status display
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Current Focus: ${_getFocusName()}'),
                Text('Last Action: $lastAction'),
                Text('Expand Behavior: ${_getExpandBehaviorName()}'),
              ],
            ),
          ),

          // Mind Map
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
                  style: const MindMapStyle(
                    levelSpacing: 120,
                    nodeMargin: 15,
                    enableAutoSizing: true,
                  ),
                  cameraFocus: currentFocus,
                  focusNodeId: targetNodeId,
                  focusAnimation: const Duration(), // Longer animation
                  isNodesCollapsed: false, // All nodes expanded
                  nodeExpandCameraBehavior:
                      NodeExpandCameraBehavior.fitExpandedSubtree,
                  onNodeTap: (node) {
                    debugPrint('Tapped Node: ${node.description} (${node.id})');
                    setState(() {
                      lastAction = 'Node Tapped: ${node.description}';
                      // Example of editing the tapped node
                      _editNode(node);
                    });
                  },
                  centerOffset: const Offset(0, 0),
                  autoCenterOnScreen: true,
                  debugMode: true,
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
          'Move to ${_getFocusName()} ${nodeId != null ? '→ $nodeId' : ''}';
    });
  }

  String _getFocusName() {
    switch (currentFocus) {
      case CameraFocus.rootNode:
        return 'Root';
      case CameraFocus.allNodes:
        return 'Fit All';
      case CameraFocus.fitAllNodes:
        return 'Fit All Nodes';
      case CameraFocus.custom:
        return 'Custom';
      case CameraFocus.center:
        return 'Center';
      case CameraFocus.firstLeaf:
        return 'First Leaf';
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
        return '❌ None';
      case NodeExpandCameraBehavior.focusClickedNode:
        return '🎯 Clicked Node';
      case NodeExpandCameraBehavior.fitExpandedChildren:
        return '👶 Children Only';
      case NodeExpandCameraBehavior.fitExpandedSubtree:
        return '🌳 Subtree';
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
      lastAction = 'Move to next node: ${nextNode.description}';
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
      lastAction = 'Move to prev node: ${prevNode.description}';
    });
  }
}
