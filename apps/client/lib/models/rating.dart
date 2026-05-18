/// Simple Rating model without Freezed - regular Dart class
class Rating {
  final int? id;
  final double grade; // Go: Grade (float32)
  final String note; // Go: Note (string)
  final int authorId; // Go: AuthorID
  final int itemId; // Go: ItemID
  // Populated relations (when available from backend) - using dynamic to avoid circular imports
  final dynamic author; // Will be User when populated
  final dynamic viewers; // Will be List<User> when populated
  final dynamic cheese; // Will be Cheese when populated

  const Rating({
    this.id,
    required this.grade,
    required this.note,
    required this.authorId,
    required this.itemId,
    this.author,
    this.viewers,
    this.cheese,
  });

  /// Create from JSON - matches Go backend exactly
  factory Rating.fromJson(Map<String, dynamic> json) {
    try {
      return Rating(
        id: json['ID'] as int?,
        grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
        note: (json['note'] ?? '') as String,
        authorId: json['user_id'] as int,
        itemId: json['item_id'] as int,
        author: json['user'] ?? json['User'], // Go backend sends 'user' (lowercase) with OAuth
        viewers: json['viewers'],
        cheese: json['cheese'],
      );
    } catch (e) {
      // Only log JSON parsing errors in debug mode or for critical issues
      throw Exception('Failed to parse Rating from JSON: $e');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'note': note,
      'author_id': authorId,
      'item_id': itemId,
      'author': author, // Keep as-is since backend sends it as JSON
      'viewers': viewers, // Keep as-is since backend sends it as JSON
      'cheese': cheese, // Keep as-is since backend sends it as JSON
    };
  }

  /// Convert to JSON for API creation (matches backend expectations)
  Map<String, dynamic> toCreateJson() {
    return {
      'grade': grade,
      'note': note,
      'item_id': itemId,
    };
  }

  /// Convert to JSON for API update (matches backend expectations)
  Map<String, dynamic> toUpdateJson() {
    return {
      'grade': grade,
      'note': note,
      'item_id': itemId,
    };
  }

  /// Create a copy with some fields updated
  Rating copyWith({
    int? id,
    double? grade,
    String? note,
    int? authorId,
    int? itemId,
    dynamic author,
    dynamic viewers,
    dynamic cheese,
  }) {
    return Rating(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      note: note ?? this.note,
      authorId: authorId ?? this.authorId,
      itemId: itemId ?? this.itemId,
      author: author ?? this.author,
      viewers: viewers ?? this.viewers,
      cheese: cheese ?? this.cheese,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rating &&
        other.id == id &&
        other.grade == grade &&
        other.note == note &&
        other.authorId == authorId &&
        other.itemId == itemId;
  }

  @override
  int get hashCode {
    return Object.hash(id, grade, note, authorId, itemId);
  }

  @override
  String toString() {
    return 'Rating(id: $id, grade: $grade, note: $note, authorId: $authorId, itemId: $itemId)';
  }
}

/// Extension for Rating convenience methods
extension RatingExtension on Rating {
  /// Check if rating is new (no ID)
  bool get isNew => id == null;

  /// Check if rating has a note
  bool get hasNote => note.isNotEmpty;

  /// Get star rating as integer (for UI display)
  int get starRating => grade.round();

  /// Get author display name (privacy-safe)
  String get authorName {
    if (author != null && author is Map<String, dynamic>) {
      // Only use display_name - the name users chose to share publicly
      final displayName = author['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    }
    // Privacy-safe fallback - never show real names or emails
    return 'Anonymous User';
  }

  /// Get viewer display names
  String get viewerNames {
    if (viewers != null && viewers is List) {
      final names = (viewers as List)
          .where((v) => v is Map<String, dynamic> && v['name'] != null)
          .map((v) => v['name'] as String)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    return 'No viewers';
  }

  /// Check if rating is visible to current user
  bool isVisibleToUser(int userId) {
    if (authorId == userId) return true;

    if (viewers != null && viewers is List) {
      return (viewers as List).any(
        (v) => v is Map<String, dynamic> && (v['id'] == userId || v['ID'] == userId),
      );
    }

    return false;
  }

  /// Check if current user can edit this rating
  bool canEditByUser(int userId) {
    return authorId == userId;
  }
}

/// Rating creation helper
class RatingBuilder {
  static Rating createNew({
    required double grade,
    required String note,
    required int authorId,
    required int itemId,
  }) {
    return Rating(
      grade: grade,
      note: note,
      authorId: authorId,
      itemId: itemId,
    );
  }

  static Rating createCheeseRating({
    required double grade,
    required String note,
    required int authorId,
    required int cheeseId,
  }) {
    return createNew(
      grade: grade,
      note: note,
      authorId: authorId,
      itemId: cheeseId,
    );
  }
}
