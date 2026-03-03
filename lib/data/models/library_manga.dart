import 'dart:convert';

class LibraryManga {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String? url;
  final String type;
  final DateTime addedAt;
  final double currentChapter;
  final int currentPage;
  final int totalPages;
  final bool isCompleted;

  LibraryManga({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    this.url,
    required this.type,
    required this.addedAt,
    required this.currentChapter,
    required this.currentPage,
    required this.totalPages,
    required this.isCompleted,
  });

  factory LibraryManga.fromMangaDetail(
    String id,
    String title,
    String author,
    String imageUrl,
    String? url,
    String type,
  ) {
    return LibraryManga(
      id: id,
      title: title,
      author: author,
      imageUrl: imageUrl,
      url: url,
      type: type,
      addedAt: DateTime.now(),
      currentChapter: 0.0,
      currentPage: 0,
      totalPages: 0,
      isCompleted: false,
    );
  }

  factory LibraryManga.fromMap(Map<String, dynamic> map) {
    return LibraryManga(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      imageUrl: map['imageUrl'] as String,
      url: map['url'] as String?,
      type: map['type'] as String,
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'] as String)
          : DateTime.now(),
      currentChapter: (map['currentChapter'] as num? ?? 0).toDouble(),
      currentPage: map['currentPage'] as int? ?? 1,
      totalPages: map['totalPages'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'url': url,
      'type': type,
      'addedAt': addedAt.toIso8601String(),
      'currentChapter': currentChapter,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': isCompleted,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory LibraryManga.fromJson(String source) =>
      LibraryManga.fromMap(jsonDecode(source) as Map<String, dynamic>);

  LibraryManga copyWith({
    String? id,
    String? title,
    String? author,
    String? imageUrl,
    String? url,
    String? type,
    DateTime? addedAt,
    double? currentChapter,
    int? currentPage,
    int? totalPages,
    bool? isCompleted,
  }) {
    return LibraryManga(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      currentChapter: currentChapter ?? this.currentChapter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }
}
