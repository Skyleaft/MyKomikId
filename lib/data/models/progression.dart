import 'dart:convert';

class MangaProgression {
  final String mangaId;
  final String chapterId; // new API field
  final double currentChapter; // API's chapterNumber
  final int currentPage; // API's lastReadPage
  final int totalPages;
  final DateTime lastRead; // API's lastReadAt
  final bool isCompleted;
  final int readingTimeSeconds; // new API field

  MangaProgression({
    required this.mangaId,
    this.chapterId = "",
    required this.currentChapter,
    required this.currentPage,
    required this.totalPages,
    required this.lastRead,
    required this.isCompleted,
    this.readingTimeSeconds = 0,
  });

  factory MangaProgression.fromMap(Map<String, dynamic> map) {
    return MangaProgression(
      mangaId: map['mangaId'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? "",
      currentChapter: ((map['chapterNumber'] ?? map['currentChapter'] ?? 0) as num).toDouble(),
      currentPage: (map['lastReadPage'] ?? map['currentPage'] ?? 1) as int,
      totalPages: (map['totalPages'] ?? 1) as int,
      lastRead: _parseDate(map['lastReadAt'] ?? map['lastRead']),
      isCompleted: map['isCompleted'] as bool? ?? false,
      readingTimeSeconds: map['readingTimeSeconds'] as int? ?? 0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'mangaId': mangaId,
      'chapterId': chapterId,
      'currentChapter': currentChapter,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'lastRead': lastRead.toIso8601String(),
      'isCompleted': isCompleted,
      'readingTimeSeconds': readingTimeSeconds,
    };
  }
  
  Map<String, dynamic> toApiRequest() {
    return {
      'mangaId': mangaId,
      'chapterId': chapterId,
      'chapterNumber': currentChapter,
      'lastReadPage': currentPage,
      'totalPages': totalPages,
      'readingTimeSeconds': readingTimeSeconds,
      // API request might not need isCompleted or lastRead.
    };
  }

  String toJson() => jsonEncode(toMap());

  factory MangaProgression.fromJson(String source) =>
      MangaProgression.fromMap(jsonDecode(source) as Map<String, dynamic>);

  MangaProgression copyWith({
    String? mangaId,
    String? chapterId,
    double? currentChapter,
    int? currentPage,
    int? totalPages,
    DateTime? lastRead,
    bool? isCompleted,
    int? readingTimeSeconds,
  }) {
    return MangaProgression(
      mangaId: mangaId ?? this.mangaId,
      chapterId: chapterId ?? this.chapterId,
      currentChapter: currentChapter ?? this.currentChapter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastRead: lastRead ?? this.lastRead,
      isCompleted: isCompleted ?? this.isCompleted,
      readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
    );
  }

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }
}
