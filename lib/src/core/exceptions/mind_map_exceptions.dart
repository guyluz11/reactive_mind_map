/// Custom exceptions for the mind map package
class MindMapException implements Exception {
  final String message;
  final dynamic cause;

  MindMapException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'MindMapException: $message\nCaused by: $cause';
    }
    return 'MindMapException: $message';
  }
}

/// Exception thrown when layout calculation fails
class LayoutException extends MindMapException {
  LayoutException(super.message, [super.cause]);

  @override
  String toString() => 'LayoutException: $message';
}

/// Exception thrown when camera operations fail
class CameraException extends MindMapException {
  CameraException(super.message, [super.cause]);

  @override
  String toString() => 'CameraException: $message';
}

/// Exception thrown when node operations fail
class NodeException extends MindMapException {
  NodeException(super.message, [super.cause]);

  @override
  String toString() => 'NodeException: $message';
}

/// Exception thrown when animation operations fail
class AnimationException extends MindMapException {
  AnimationException(super.message, [super.cause]);

  @override
  String toString() => 'AnimationException: $message';
}
