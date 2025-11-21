// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_mind_map/reactive_mind_map.dart';

void main() {
  group('MindMapWidget Tests', () {
    testWidgets('MindMapWidget 기본 렌더링 테스트', (WidgetTester tester) async {
      final testData = MindMapData(
        id: 'test_root',
        content: const Text('Test Root'),
        description: 'Test root node',
        children: [
          MindMapData(
            id: 'child1',
            content: const Text('Child 1'),
            description: 'First child',
          ),
          MindMapData(
            id: 'child2',
            content: const Text('Child 2'),
            description: 'Second child',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MindMapWidget(data: testData))),
      );

      // 루트 노드가 렌더링되는지 확인
      expect(find.text('Test Root'), findsOneWidget);

      // 위젯이 정상적으로 빌드되는지 확인
      expect(find.byType(MindMapWidget), findsOneWidget);
    });

    testWidgets('MindMapWidget 스타일 적용 테스트', (WidgetTester tester) async {
      final testData = MindMapData(
        id: 'styled_root',
        content: const Text('Styled Root'),
        description: 'Root with style',
      );

      const customStyle = MindMapStyle(
        layout: MindMapLayout.left,
        nodeShape: NodeShape.circle,
        backgroundColor: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(data: testData, style: customStyle),
          ),
        ),
      );

      expect(find.byType(MindMapWidget), findsOneWidget);
      expect(find.text('Styled Root'), findsOneWidget);
    });

    testWidgets('MindMapWidget 콜백 테스트', (WidgetTester tester) async {
      final testData = MindMapData(
        id: 'callback_root',
        content: const Text('Callback Root'),
        description: 'Root for callback test',
      );

      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              data: testData,
              canvasSize: const Size(800, 600),
              onNodeTap: (node) {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 위젯이 정상적으로 빌드되는지 확인
      expect(find.byType(MindMapWidget), findsOneWidget);
      expect(find.text('Callback Root'), findsOneWidget);

      // 콜백 함수가 설정되어 있는지 확인 (직접 탭 테스트는 생략)
      expect(callbackCalled, isFalse); // 아직 탭하지 않았으므로 false
    });
  });

  group('MindMapData Tests', () {
    test('MindMapData 생성 및 속성 테스트', () {
      final data = MindMapData(
        id: 'test_id',
        content: const Text('Test Title'),
        description: 'Test Description',
        color: Colors.blue,
        children: [
          MindMapData(id: 'child_id', content: const Text('Child Title')),
        ],
      );

      expect(data.id, equals('test_id'));
      expect(data.content, isA<Text>());
      expect(data.description, equals('Test Description'));
      expect(data.color, equals(Colors.blue));
      expect(data.children.length, equals(1));
      expect(data.children.first.id, equals('child_id'));
    });

    test('MindMapData copyWith 테스트', () {
      final original = MindMapData(
        id: 'original_id',
        content: const Text('Original Title'),
        description: 'Original Description',
      );

      final copied = original.copyWith(
        content: const Text('New Title'),
        description: 'New Description',
      );

      expect(copied.id, equals('original_id')); // 변경되지 않음
      expect(copied.content, isA<Text>()); // 변경됨
      expect((copied.content as Text).data, equals('New Title'));
      expect(copied.description, equals('New Description')); // 변경됨
    });
  });

  group('MindMapStyle Tests', () {
    test('MindMapStyle 기본값 테스트', () {
      const style = MindMapStyle();

      expect(style.layout, equals(MindMapLayout.right));
      expect(style.nodeShape, equals(NodeShape.roundedRectangle));
      expect(style.backgroundColor, equals(const Color(0xFFF8FAFC)));
      expect(style.levelSpacing, equals(240.0));
      expect(style.nodeMargin, equals(40.0));
    });

    test('MindMapStyle copyWith 테스트', () {
      const original = MindMapStyle();

      final modified = original.copyWith(
        layout: MindMapLayout.left,
        nodeShape: NodeShape.circle,
        backgroundColor: Colors.black,
      );

      expect(modified.layout, equals(MindMapLayout.left));
      expect(modified.nodeShape, equals(NodeShape.circle));
      expect(modified.backgroundColor, equals(Colors.black));
      expect(modified.levelSpacing, equals(240.0)); // 변경되지 않음
    });

    test('MindMapStyle 헬퍼 메소드 테스트', () {
      const style = MindMapStyle();

      // 노드 크기 테스트
      expect(style.getNodeSize(0), equals(80.0)); // 루트
      expect(style.getNodeSize(1), equals(60.0)); // 1차 자식
      expect(style.getNodeSize(2), equals(45.0)); // 리프

      // 기본 색상 테스트
      expect(style.getDefaultNodeColor(0), isA<Color>());
      expect(style.getDefaultNodeColor(1), isA<Color>());
    });
  });
}
