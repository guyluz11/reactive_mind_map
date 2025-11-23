/// Mind map type
enum MindMapType {
  /// Default mind map
  default_,

  // /// Markmap style mind map
  // markmap, // in development
}

/// Mind map type extension methods
extension MindMapTypeExtension on MindMapType {
  /// Display name of mind map type
  String get displayName {
    switch (this) {
      case MindMapType.default_:
        return 'Default';
      // case MindMapType.markmap:
      // return 'Markmap';
    }
  }

  /// Description of mind map type
  String get description {
    switch (this) {
      case MindMapType.default_:
        return 'Basic mind map structure';
      // case MindMapType.markmap:
      // return 'markmap.js style horizontal tree structure';
    }
  }

  /// Icon of mind map type
  String get icon {
    switch (this) {
      case MindMapType.default_:
        return '🧠';
      // case MindMapType.markmap:
      //   return '📈';
    }
  }
}
