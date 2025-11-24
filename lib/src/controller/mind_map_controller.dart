import 'package:flutter/widgets.dart';

import '../features/node/models/mind_map_node.dart';

/// Delegate interface for the controller to interact with the widget state
abstract class MindMapControllerDelegate {
  /// Zoom to fit all nodes
  Future<void> zoomToFit();

  /// Focus on the next node
  Future<void> focusNext();

  /// Focus on the previous node
  Future<void> focusPrevious();

  /// Focus on a specific node by ID
  Future<void> focusNode(String nodeId);

  /// Modify a node at a specific index in the focusable list
  void modifyNodeAt(int index, MindMapNode Function(MindMapNode node) update);

  /// Modify a node by its ID
  void modifyNode(String nodeId, MindMapNode Function(MindMapNode node) update);
}

/// Controller for the MindMapWidget
///
/// Allows external control of the mind map, such as programmatic navigation and zooming.
class MindMapController extends ChangeNotifier {
  MindMapControllerDelegate? _delegate;

  /// Attach the delegate (called by the widget state)
  void attach(MindMapControllerDelegate delegate) {
    _delegate = delegate;
  }

  /// Detach the delegate (called by the widget state)
  void detach() {
    _delegate = null;
  }

  /// Zoom to fit all nodes in the viewport
  Future<void> zoomToFit() async {
    await _delegate?.zoomToFit();
  }

  /// Focus on the next node in the traversal order
  Future<void> focusNext() async {
    await _delegate?.focusNext();
  }

  /// Focus on the previous node in the traversal order
  Future<void> focusPrevious() async {
    await _delegate?.focusPrevious();
  }

  /// Focus on a specific node by its ID
  Future<void> focusNode(String nodeId) async {
    await _delegate?.focusNode(nodeId);
  }

  /// Modify a node at a specific index in the focusable list
  void modifyNodeAt(int index, MindMapNode Function(MindMapNode node) update) {
    _delegate?.modifyNodeAt(index, update);
  }

  /// Modify a node by its ID
  void modifyNode(
    String nodeId,
    MindMapNode Function(MindMapNode node) update,
  ) {
    _delegate?.modifyNode(nodeId, update);
  }
}
