import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_mind_map/reactive_mind_map.dart';

void main() {
  testWidgets('focusZoomOutFactor controls zoom level when focusing', (
    WidgetTester tester,
  ) async {
    final controller = MindMapController();
    final data = MindMapData(
      id: 'root',
      content: const Text('Root'),
      children: [MindMapData(id: 'child1', content: const Text('Child 1'))],
    );

    // Test with default zoom factor (1.0)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MindMapWidget(
            data: data,
            controller: controller,
            focusZoomOutFactor: 1.0, // Default - node fills viewport
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Focus on child node
    controller.focusNode('child1');
    await tester.pumpAndSettle();

    // Widget should build without errors
    expect(find.text('Child 1'), findsOneWidget);
  });

  testWidgets('focusZoomOutFactor 1.5 shows more context', (
    WidgetTester tester,
  ) async {
    final controller = MindMapController();
    final data = MindMapData(
      id: 'root',
      content: const Text('Root'),
      children: [MindMapData(id: 'child1', content: const Text('Child 1'))],
    );

    // Test with zoom out factor of 1.5
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MindMapWidget(
            data: data,
            controller: controller,
            focusZoomOutFactor: 1.5, // Show 50% more context
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Focus on child node
    controller.focusNode('child1');
    await tester.pumpAndSettle();

    // Widget should build without errors and show more context
    expect(find.text('Child 1'), findsOneWidget);
    expect(find.text('Root'), findsOneWidget); // Root should also be visible
  });
}
