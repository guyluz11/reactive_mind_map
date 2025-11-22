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
      title: 'Reactive Mind Map Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MindMapLayout _selectedLayout = MindMapLayout.right;
  NodeShape _selectedShape = NodeShape.roundedRectangle;
  bool _useCustomAnimation = false;
  bool _showNodeShadows = true;
  bool _useBoldConnections = false;

  // Node type selection
  NodeType _selectedNodeType = NodeType.basic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactive Mind Map Package'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildLayoutMenu(),
          _buildNodeTypeMenu(),
          _buildShapeMenu(),
          _buildSettingsMenu(),
        ],
      ),
      body: MindMapWidget(
        data: _getUnifiedData(),
        style: _getStyleForNodeType(_selectedNodeType),
        onNodeTap: _handleNodeTap,
        onNodeLongPress: _handleNodeLongPress,
      ),
      floatingActionButton: _buildInfoButton(),
    );
  }

  // MARK: - Menu Builders

  Widget _buildLayoutMenu() {
    return PopupMenuButton<MindMapLayout>(
      icon: const Icon(Icons.view_quilt),
      tooltip: 'Change Layout',
      onSelected: (layout) => setState(() => _selectedLayout = layout),
      itemBuilder:
          (context) =>
              MindMapLayout.values.map((layout) {
                return PopupMenuItem(
                  value: layout,
                  child: Text(_getLayoutName(layout)),
                );
              }).toList(),
    );
  }

  Widget _buildNodeTypeMenu() {
    return PopupMenuButton<NodeType>(
      icon: const Icon(Icons.dashboard),
      tooltip: 'Select Node Type',
      onSelected: (type) => setState(() => _selectedNodeType = type),
      itemBuilder:
          (context) =>
              NodeType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
    );
  }

  Widget _buildShapeMenu() {
    return PopupMenuButton<NodeShape>(
      icon: const Icon(Icons.category),
      tooltip: 'Change Shape',
      onSelected: (shape) => setState(() => _selectedShape = shape),
      itemBuilder:
          (context) =>
              NodeShape.values.map((shape) {
                return PopupMenuItem(
                  value: shape,
                  child: Text(_getShapeName(shape)),
                );
              }).toList(),
    );
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: 'Advanced Settings',
      itemBuilder:
          (context) => [
            _buildSettingItem(
              'animation',
              'Fast Animation',
              _useCustomAnimation,
            ),
            _buildSettingItem('shadows', 'Node Shadows', _showNodeShadows),
            _buildSettingItem(
              'connections',
              'Bold Connections',
              _useBoldConnections,
            ),
          ],
      onSelected: _handleSettingChange,
    );
  }

  PopupMenuItem<String> _buildSettingItem(
    String value,
    String title,
    bool isEnabled,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(isEnabled ? Icons.check_box : Icons.check_box_outline_blank),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildInfoButton() {
    return FloatingActionButton(
      onPressed: _showInfoDialog,
      child: const Icon(Icons.info),
    );
  }

  // MARK: - 통합 데이터 및 스타일

  // MARK: - Unified Data & Style

  MindMapData _getUnifiedData() {
    return MindMapData(
      id: 'root',
      content: const Text(
        'Project Management System',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: 'Complete Project Lifecycle',
      color: const Color(0xFF3B82F6),
      children: [
        MindMapData(
          id: 'planning',
          content: const Text(
            'Planning Phase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          description: 'Project Planning & Design',
          color: const Color(0xFF10B981),
          customData: {'icon': '📝', 'priority': 'high'},
          children: [
            MindMapData(
              id: 'planning-1',
              content: const Text(
                'Requirements Analysis',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Identify & Analyze User Needs',
              color: const Color(0xFF059669),
              customData: {'icon': '🔍', 'department': 'PM'},
              children: [
                MindMapData(
                  id: 'planning-1-1',
                  content: const Text(
                    'User Interviews',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Direct User Interviews',
                  color: const Color(0xFF047857),
                  customData: {'icon': '👥', 'method': 'interview'},
                ),
                MindMapData(
                  id: 'planning-1-2',
                  content: const Text(
                    'Market Research',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Competitor & Market Analysis',
                  color: const Color(0xFF065F46),
                  customData: {'icon': '📊', 'method': 'research'},
                ),
              ],
            ),
            MindMapData(
              id: 'planning-2',
              content: const Text(
                'Feature Definition',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Define Core Features & Requirements',
              color: const Color(0xFF047857),
              customData: {'icon': '⚙️', 'department': 'UX'},
              children: [
                MindMapData(
                  id: 'planning-2-1',
                  content: const Text(
                    'User Stories',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Define Features from User Perspective',
                  color: const Color(0xFF065F46),
                  customData: {'icon': '📖', 'type': 'story'},
                ),
                MindMapData(
                  id: 'planning-2-2',
                  content: const Text(
                    'Functional Spec',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Detailed Functional Specifications',
                  color: const Color(0xFF064E3B),
                  customData: {'icon': '📋', 'type': 'spec'},
                ),
              ],
            ),
            MindMapData(
              id: 'planning-3',
              content: const Text(
                'Architecture Design',
                style: TextStyle(color: Colors.white),
              ),
              description: 'System Architecture Design',
              color: const Color(0xFF065F46),
              customData: {'icon': '🏗️', 'department': 'Architecture'},
            ),
          ],
        ),
        MindMapData(
          id: 'development',
          content: const Text(
            'Development Phase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          description: 'Actual Code Implementation',
          color: const Color(0xFFF59E0B),
          customData: {'icon': '💻', 'priority': 'medium'},
          children: [
            MindMapData(
              id: 'development-1',
              content: const Text(
                'Frontend',
                style: TextStyle(color: Colors.white),
              ),
              description: 'User Interface Development',
              color: const Color(0xFFDC2626),
              customData: {'icon': '🖥️', 'tech': 'Flutter'},
              children: [
                MindMapData(
                  id: 'development-1-1',
                  content: const Text(
                    'UI Components',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Reusable UI Components',
                  color: const Color(0xFFB91C1C),
                  customData: {'icon': '🧩', 'type': 'component'},
                ),
                MindMapData(
                  id: 'development-1-2',
                  content: const Text(
                    'Page Implementation',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Implement Screens per Page',
                  color: const Color(0xFF991B1B),
                  customData: {'icon': '📄', 'type': 'page'},
                ),
                MindMapData(
                  id: 'development-1-3',
                  content: const Text(
                    'State Management',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Application State Management',
                  color: const Color(0xFF7F1D1D),
                  customData: {'icon': '🔄', 'type': 'state'},
                ),
              ],
            ),
            MindMapData(
              id: 'development-2',
              content: const Text(
                'Backend',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Server Logic & API Development',
              color: const Color(0xFF7C3AED),
              customData: {'icon': '⚙️', 'tech': 'Node.js'},
              children: [
                MindMapData(
                  id: 'development-2-1',
                  content: const Text(
                    'API Endpoints',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Implement RESTful APIs',
                  color: const Color(0xFF6D28D9),
                  customData: {'icon': '🔗', 'type': 'api'},
                ),
                MindMapData(
                  id: 'development-2-2',
                  content: const Text(
                    'Database',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Database Design & Implementation',
                  color: const Color(0xFF5B21B6),
                  customData: {'icon': '🗄️', 'type': 'database'},
                ),
                MindMapData(
                  id: 'development-2-3',
                  content: const Text(
                    'Auth System',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'User Auth & Permission Management',
                  color: const Color(0xFF4C1D95),
                  customData: {'icon': '🔐', 'type': 'auth'},
                ),
              ],
            ),
            MindMapData(
              id: 'development-3',
              content: const Text(
                'DevOps',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Deployment & Infrastructure',
              color: const Color(0xFF059669),
              customData: {'icon': '🚀', 'tech': 'Docker'},
              children: [
                MindMapData(
                  id: 'development-3-1',
                  content: const Text(
                    'CI/CD Pipeline',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'Continuous Integration & Deployment',
                  color: const Color(0xFF047857),
                  customData: {'icon': '⚡', 'type': 'pipeline'},
                ),
                MindMapData(
                  id: 'development-3-2',
                  content: const Text(
                    'Monitoring',
                    style: TextStyle(color: Colors.white),
                  ),
                  description: 'System Monitoring & Logging',
                  color: const Color(0xFF065F46),
                  customData: {'icon': '📊', 'type': 'monitoring'},
                ),
              ],
            ),
          ],
        ),
        MindMapData(
          id: 'testing',
          content: const Text(
            'Testing Phase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          description: 'QA & Testing',
          color: const Color(0xFF8B5CF6),
          customData: {'icon': '🧪', 'priority': 'low'},
          children: [
            MindMapData(
              id: 'testing-1',
              content: const Text(
                'Unit Testing',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Individual Component Testing',
              color: const Color(0xFF7C3AED),
              customData: {'icon': '🔬', 'type': 'unit'},
            ),
            MindMapData(
              id: 'testing-2',
              content: const Text(
                'Integration Testing',
                style: TextStyle(color: Colors.white),
              ),
              description: 'System Integration Testing',
              color: const Color(0xFF6D28D9),
              customData: {'icon': '🔗', 'type': 'integration'},
            ),
            MindMapData(
              id: 'testing-3',
              content: const Text(
                'User Testing',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Real User Environment Testing',
              color: const Color(0xFF5B21B6),
              customData: {'icon': '👥', 'type': 'user'},
            ),
          ],
        ),
        MindMapData(
          id: 'deployment',
          content: const Text(
            'Deployment Phase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          description: 'Deploy to Production',
          color: const Color(0xFFEF4444),
          customData: {'icon': '🚀', 'priority': 'high'},
          children: [
            MindMapData(
              id: 'deployment-1',
              content: const Text(
                'Staging Deployment',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Deploy to Test Environment',
              color: const Color(0xFFDC2626),
              customData: {'icon': '🧪', 'env': 'staging'},
            ),
            MindMapData(
              id: 'deployment-2',
              content: const Text(
                'Production Deployment',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Deploy to Live Service',
              color: const Color(0xFFB91C1C),
              customData: {'icon': '🌐', 'env': 'production'},
            ),
          ],
        ),
        MindMapData(
          id: 'maintenance',
          content: const Text(
            'Maintenance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          description: 'Continuous Service Management',
          color: const Color(0xFF6B7280),
          customData: {'icon': '🔧', 'priority': 'medium'},
          children: [
            MindMapData(
              id: 'maintenance-1',
              content: const Text(
                'Bug Fixes',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Fix Identified Issues',
              color: const Color(0xFF4B5563),
              customData: {'icon': '🐛', 'type': 'bugfix'},
            ),
            MindMapData(
              id: 'maintenance-2',
              content: const Text(
                'Performance Optimization',
                style: TextStyle(color: Colors.white),
              ),
              description: 'Improve System Performance',
              color: const Color(0xFF374151),
              customData: {'icon': '⚡', 'type': 'optimization'},
            ),
          ],
        ),
      ],
    );
  }

  MindMapStyle _getStyleForNodeType(NodeType type) {
    switch (type) {
      case NodeType.basic:
        return _getBasicStyle();
      case NodeType.custom:
        return _getCustomStyle();
    }
  }

  // MARK: - Style Definitions

  MindMapStyle _getBasicStyle() {
    return MindMapStyle(
      layout: _selectedLayout,
      nodeShape: _selectedShape,
      animationDuration:
          _useCustomAnimation
              ? const Duration(milliseconds: 300)
              : const Duration(milliseconds: 600),
      animationCurve:
          _useCustomAnimation ? Curves.easeInOut : Curves.easeOutCubic,
      enableNodeShadow: _showNodeShadows,
      nodeShadowColor: Colors.black.withValues(alpha: 0.3),
      nodeShadowBlurRadius: 8,
      nodeShadowSpreadRadius: 2,
      nodeShadowOffset: const Offset(2, 4),
      connectionWidth: _useBoldConnections ? 3.0 : 2.0,
      connectionColor:
          _useBoldConnections
              ? Colors.black87
              : Colors.grey.withValues(alpha: 0.6),
      useCustomCurve: true,
      backgroundColor: Colors.grey[50]!,
      levelSpacing: 160,
      nodeMargin: 15,
    );
  }

  MindMapStyle _getCustomStyle() {
    return MindMapStyle(
      layout: _selectedLayout,
      nodeShape: _selectedShape,
      animationDuration:
          _useCustomAnimation
              ? const Duration(milliseconds: 300)
              : const Duration(milliseconds: 600),
      animationCurve:
          _useCustomAnimation ? Curves.easeInOut : Curves.easeOutCubic,
      enableNodeShadow: _showNodeShadows,
      nodeShadowColor: Colors.black.withValues(alpha: 0.3),
      nodeShadowBlurRadius: 8,
      nodeShadowSpreadRadius: 2,
      nodeShadowOffset: const Offset(2, 4),
      connectionWidth: _useBoldConnections ? 3.0 : 2.0,
      connectionColor:
          _useBoldConnections
              ? Colors.black87
              : Colors.grey.withValues(alpha: 0.6),
      useCustomCurve: true,
      backgroundColor: Colors.grey[50]!,
      levelSpacing: 160,
      nodeMargin: 15,
      nodeBuilder:
          _buildStyleLevelCustomNode, // Set node builder at style level
    );
  }

  // MARK: - Style Level Custom Node Builder
  Widget _buildStyleLevelCustomNode(
    MindMapNode node,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback onLongPress,
    VoidCallback onDoubleTap,
  ) {
    final icon = node.customData?['icon'] as String? ?? '📋';
    final priority = node.customData?['priority'] as String? ?? 'medium';

    final actualSize = const MindMapStyle().getActualNodeSize(node.level);

    // Layout based on node size
    final isSmallNode = actualSize.width < 80 || actualSize.height < 50;
    final canShowPriority = !isSmallNode && actualSize.width >= 60;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: actualSize.width,
        height: actualSize.height,
        decoration: BoxDecoration(
          color: node.color,
          borderRadius: BorderRadius.circular(
            12,
          ), // Rounder corners for style version
          border: Border.all(
            color: _getPriorityColor(priority),
            width: 2,
          ), // Thinner border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .15),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: Colors.yellow.withValues(alpha: .5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallNode ? 4.0 : 6.0), // Smaller padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and priority tag
                if (!isSmallNode) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        icon,
                        style: const TextStyle(fontSize: 12),
                      ), // Smaller icon
                      if (canShowPriority) ...[
                        const SizedBox(width: 3),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                priority,
                              ).withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(priority),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                ] else ...[
                  Text(icon, style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 1),
                ],
                // Title text (using node.content)
                Flexible(child: node.content),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Helper Methods

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // MARK: - Event Handlers

  void _handleNodeTap(MindMapData node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap: ${node.description}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleNodeLongPress(MindMapData node) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(node.description),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${node.id}'),
                const SizedBox(height: 8),
                Text('Desc: ${node.description}'),
                const SizedBox(height: 8),
                Text('Children: ${node.children.length}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _handleSettingChange(String value) {
    setState(() {
      switch (value) {
        case 'animation':
          _useCustomAnimation = !_useCustomAnimation;
          break;
        case 'shadows':
          _showNodeShadows = !_showNodeShadows;
          break;
        case 'connections':
          _useBoldConnections = !_useBoldConnections;
          break;
      }
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reactive Mind Map Package'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎨 Fully Customizable'),
                Text('🎯 Various Layouts'),
                Text('⚡ Smooth Animations'),
                Text('🖱️ Rich Interactions'),
                SizedBox(height: 16),
                Text('Change layout and shape from the top menu!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getLayoutName(MindMapLayout layout) {
    switch (layout) {
      case MindMapLayout.right:
        return 'Right';
      case MindMapLayout.left:
        return 'Left';
      case MindMapLayout.top:
        return 'Top';
      case MindMapLayout.bottom:
        return 'Bottom';
      case MindMapLayout.radial:
        return 'Radial';
      case MindMapLayout.horizontal:
        return 'Horizontal';
      case MindMapLayout.vertical:
        return 'Vertical';
    }
  }

  String _getShapeName(NodeShape shape) {
    switch (shape) {
      case NodeShape.roundedRectangle:
        return 'Rounded Rect';
      case NodeShape.circle:
        return 'Radial';
      case NodeShape.rectangle:
        return 'Rectangle';
      case NodeShape.diamond:
        return 'Diamond';
      case NodeShape.hexagon:
        return 'Hexagon';
      case NodeShape.ellipse:
        return 'Ellipse';
    }
  }
}

// MARK: - Node Type Enum

enum NodeType {
  basic('🧠', 'Basic Node'),
  custom('⚡', 'Widget Custom');

  const NodeType(this.icon, this.displayName);
  final String icon;
  final String displayName;
}
