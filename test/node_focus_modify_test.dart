import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_mind_map/reactive_mind_map.dart';

void main() {
  testWidgets('onNodeFocused callback fires when focusing nodes', (
    WidgetTester tester,
  ) async {
    final controller = MindMapController();
    final data = MindMapData(
      id: 'root',
      content: const Text('Root'),
      children: [
        MindMapData(id: 'child1', content: const Text('Child 1')),
        MindMapData(id: 'child2', content: const Text('Child 2')),
      ],
    );

    MindMapNode? focusedNode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MindMapWidget(
            data: data,
            controller: controller,
            onNodeFocused: (node) {
              focusedNode = node;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Test focusNext
    controller.focusNext();
    await tester.pumpAndSettle();
    expect(focusedNode, isNotNull);
    final firstFocusedId = focusedNode!.id;

    // Test focusNext again
    controller.focusNext();
    await tester.pumpAndSettle();
    expect(focusedNode, isNotNull);
    expect(focusedNode!.id, isNot(equals(firstFocusedId)));

    // Test focusPrevious
    controller.focusPrevious();
    await tester.pumpAndSettle();
    expect(focusedNode, isNotNull);
    expect(focusedNode!.id, equals(firstFocusedId));

    // Test focusNode by ID
    controller.focusNode('child1');
    await tester.pumpAndSettle();
    expect(focusedNode, isNotNull);
    expect(focusedNode!.id, equals('child1'));
  });

  testWidgets('modifyNode with copyWith updates node properties', (
    WidgetTester tester,
  ) async {
    final controller = MindMapController();
    final data = MindMapData(
      id: 'root',
      content: const Text('Root'),
      children: [
        MindMapData(
          id: 'child1',
          content: const Text('Child 1'),
          color: Colors.blue,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MindMapWidget(data: data, controller: controller)),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('Child 1'), findsOneWidget);
    expect(find.text('Updated Child'), findsNothing);

    // Modify node using copyWith
    controller.modifyNode('child1', (node) {
      return node.copyWith(
        content: const Text('Updated Child'),
        color: Colors.red,
      );
    });

    await tester.pumpAndSettle();

    // Verify updated state
    expect(find.text('Child 1'), findsNothing);
    expect(find.text('Updated Child'), findsOneWidget);
  });

  testWidgets('modifyNodeAt with copyWith updates node at index', (
    WidgetTester tester,
  ) async {
    final controller = MindMapController();
    final data = MindMapData(
      id: 'root',
      content: const Text('Root'),
      children: [
        MindMapData(id: 'child1', content: const Text('Child 1')),
        MindMapData(id: 'child2', content: const Text('Child 2')),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MindMapWidget(data: data, controller: controller)),
      ),
    );

    await tester.pumpAndSettle();

    // Modify node at index 1 (should be child1 in depth-first traversal)
    controller.modifyNodeAt(1, (node) {
      return node.copyWith(content: const Text('Modified at Index 1'));
    });

    await tester.pumpAndSettle();

    // Verify the modification
    expect(find.text('Modified at Index 1'), findsOneWidget);
  });
}
