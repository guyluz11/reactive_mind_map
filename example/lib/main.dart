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
  final MindMapController _controller = MindMapController();
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
              content: const Text(
                'Sub  asd asd as das das d as das  asdasd asd asd s d as d d asdasdas das das d asdas dasd as d s1',
              ),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                        _controller.zoomToFit();
                        setState(() {
                          lastAction = 'Fit All Nodes';
                        });
                      },
                      icon: const Icon(Icons.fit_screen),
                      label: const Text('Fit All'),
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.focusPrevious();
                        setState(() {
                          lastAction = 'Focus Previous';
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous Node'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.focusNext();
                        setState(() {
                          lastAction = 'Focus Next';
                        });
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Node'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  controller: _controller,
                  data: mindMapData,
                  style: const MindMapStyle(
                    levelSpacing: 120,
                    nodeMargin: 15,
                    enableAutoSizing: true,
                  ),
                  cameraAnimationDuration: const Duration(milliseconds: 500),
                  isNodesCollapsed: false,
                  nodeExpandCameraBehavior: expandBehavior,
                  onNodeTap: (node) {
                    setState(() {
                      lastAction = 'Tapped: ${node.id}';
                    });
                  },
                  centerOffset: const Offset(0, 0),
                  autoCenterOnScreen: true,
                  debugMode: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
