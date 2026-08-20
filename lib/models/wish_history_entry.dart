import 'wish_category.dart';

/// How the user feels about a wish they made, recorded days later.
/// Order matters — kept in sync with UI mood chips.
enum WishMood {
  unknown,
  hopeful,
  peaceful,
  restless,
  sad,
  grateful;

  static WishMood fromName(String? name) {
    if (name == null) return WishMood.unknown;
    return WishMood.values.firstWhere(
      (m) => m.name == name,
      orElse: () => WishMood.unknown,
    );
  }
}

/// Whether the wish actually came true, as far as the user can tell.
/// We only ever record this if the user opts in.
enum WishOutcome {
  unknown,
  fulfilled,
  partial,
  unfulfilled;

  static WishOutcome fromName(String? name) {
    if (name == null) return WishOutcome.unknown;
    return WishOutcome.values.firstWhere(
      (o) => o.name == name,
      orElse: () => WishOutcome.unknown,
    );
  }
}

class WishHistoryEntry {
  WishHistoryEntry({
    required this.id,
    required this.category,
    required this.transcript,
    required this.response,
    required this.timestamp,
    this.notifyAt,
    DateTime? expiresAt,
    this.reflectionNote,
    this.reflectionAt,
    this.mood = WishMood.unknown,
    this.outcome = WishOutcome.unknown,
  }) : expiresAt = expiresAt ?? timestamp.add(const Duration(days: 30));

  final String id;
  final WishCategory category;
  final String transcript;
  final String response;
  final DateTime timestamp;

  /// When the universe is scheduled to "respond" with a notification.
  /// Null if the user disabled notifications or the entry was created
  /// before this field existed.
  final DateTime? notifyAt;

  /// When this wish is automatically released by the universe. Defaults
  /// to 30 days after `timestamp`. Expired entries are filtered out on
  /// load and a farewell notification is fired.
  final DateTime expiresAt;

  /// Optional short reflection written by the user days after the wish
  /// was made.
  final String? reflectionNote;

  /// When the reflection was last written/updated. Null means the user
  /// hasn't reflected yet.
  final DateTime? reflectionAt;

  /// How the user felt at the time of reflection.
  final WishMood mood;

  /// Whether the wish actually came true (user-reported).
  final WishOutcome outcome;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// True after the user has recorded any reflection (note, mood, or
  /// outcome other than unknown). Drives badge + reminder suppression.
  bool get hasReflection =>
      (reflectionNote != null && reflectionNote!.trim().isNotEmpty) ||
      mood != WishMood.unknown ||
      outcome != WishOutcome.unknown;

  /// Copy with overrides — used to update an entry without rebuilding it.
  WishHistoryEntry copyWith({
    String? reflectionNote,
    bool clearReflectionNote = false,
    DateTime? reflectionAt,
    WishMood? mood,
    WishOutcome? outcome,
    DateTime? expiresAt,
    DateTime? notifyAt,
  }) {
    return WishHistoryEntry(
      id: id,
      category: category,
      transcript: transcript,
      response: response,
      timestamp: timestamp,
      notifyAt: notifyAt ?? this.notifyAt,
      expiresAt: expiresAt ?? this.expiresAt,
      reflectionNote: clearReflectionNote
          ? null
          : reflectionNote ?? this.reflectionNote,
      reflectionAt: reflectionAt ?? this.reflectionAt,
      mood: mood ?? this.mood,
      outcome: outcome ?? this.outcome,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'transcript': transcript,
    'response': response,
    'timestamp': timestamp.toIso8601String(),
    if (notifyAt != null) 'notifyAt': notifyAt!.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    if (reflectionNote != null) 'reflectionNote': reflectionNote,
    if (reflectionAt != null) 'reflectionAt': reflectionAt!.toIso8601String(),
    'mood': mood.name,
    'outcome': outcome.name,
  };

  factory WishHistoryEntry.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String? ?? WishCategory.other.name;
    final category = WishCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => WishCategory.other,
    );
    final notifyAtRaw = json['notifyAt'] as String?;
    final timestamp = DateTime.parse(json['timestamp'] as String);
    final expiresAtRaw = json['expiresAt'] as String?;
    final reflectionAtRaw = json['reflectionAt'] as String?;
    return WishHistoryEntry(
      id: json['id'] as String,
      category: category,
      transcript: json['transcript'] as String? ?? '',
      response: json['response'] as String? ?? '',
      timestamp: timestamp,
      notifyAt: notifyAtRaw != null ? DateTime.parse(notifyAtRaw) : null,
      expiresAt: expiresAtRaw != null
          ? DateTime.parse(expiresAtRaw)
          : timestamp.add(const Duration(days: 30)),
      reflectionNote: json['reflectionNote'] as String?,
      reflectionAt: reflectionAtRaw != null
          ? DateTime.parse(reflectionAtRaw)
          : null,
      mood: WishMood.fromName(json['mood'] as String?),
      outcome: WishOutcome.fromName(json['outcome'] as String?),
    );
  }
}
