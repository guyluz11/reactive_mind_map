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
  final GlobalKey<MindMapWidgetState> _mindMapKey =
      GlobalKey<MindMapWidgetState>();
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
            MindMapData(id: 'sub2', content: Text('das')),
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
          // Camera Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _mindMapKey.currentState?.zoomToFitAll();
                        setState(() {
                          lastAction = 'Fit All Nodes';
                        });
                      },
                      icon: const Icon(Icons.fit_screen),
                      label: const Text('Fit All'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _mindMapKey.currentState?.focusNext();
                        setState(() {
                          lastAction = 'Focus Next';
                        });
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Node'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _mindMapKey.currentState?.focusPrevious();
                        setState(() {
                          lastAction = 'Focus Previous';
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous Node'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Get camera state
                        final state = _mindMapKey.currentState;
                        if (state != null) {
                          final transform =
                              state.transformationController.value;
                          final scale = transform.getMaxScaleOnAxis();
                          final translation = transform.getTranslation();

                          debugPrint('📷 ========== CAMERA DEBUG ==========');
                          debugPrint('📷 Scale: $scale');
                          debugPrint(
                            '📷 Translation: x=${translation.x}, y=${translation.y}, z=${translation.z}',
                          );

                          // Get current focused node info
                          if (state.focusableNodes.isNotEmpty &&
                              state.currentFocusedNodeIndex <
                                  state.focusableNodes.length) {
                            final currentNode =
                                state.focusableNodes[state
                                    .currentFocusedNodeIndex];
                            debugPrint('📷 Current Focused Node:');
                            debugPrint('   - ID: ${currentNode.id}');
                            debugPrint(
                              '   - Position (center): ${currentNode.position}',
                            );
                            debugPrint(
                              '   - Measured Size: ${currentNode.measuredSize}',
                            );

                            // Calculate where this node appears on screen
                            final nodeScreenX =
                                currentNode.position.dx * scale + translation.x;
                            final nodeScreenY =
                                currentNode.position.dy * scale + translation.y;
                            debugPrint(
                              '   - Screen Position: x=$nodeScreenX, y=$nodeScreenY',
                            );
                          }

                          // Get viewport size
                          final renderBox =
                              state.context.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            final viewportSize = renderBox.size;
                            final viewportCenterX = viewportSize.width / 2;
                            final viewportCenterY = viewportSize.height / 2;
                            debugPrint('📷 Viewport:');
                            debugPrint(
                              '   - Size: ${viewportSize.width} x ${viewportSize.height}',
                            );
                            debugPrint(
                              '   - Center: x=$viewportCenterX, y=$viewportCenterY',
                            );
                          }
                          debugPrint('📷 ===================================');

                          setState(() {
                            lastAction = 'Camera Debug Logged';
                          });
                        }
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Debug Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expand Behavior
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
                  key: _mindMapKey,
                  data: mindMapData,
                  style: const MindMapStyle(
                    levelSpacing: 120,
                    nodeMargin: 15,
                    enableAutoSizing: true,
                  ),
                  cameraAnimationDuration: const Duration(milliseconds: 500),
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
}
