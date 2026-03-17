import 'dart:convert';

class LibraryManga {
  final String id; // This represents mangaId from backend logic
  final String title;
  final String author;
  final String imageUrl;
  final String url;
  final String type;
  final DateTime addedAt;

  // New API fields for library
  final String status;
  final bool isFavorite;
  final double lastReadChapter;

  // Merged progression fields (fetched separately if needed but kept here for UI)
  final double currentChapter;
  final int currentPage;
  final int totalPages;
  final bool isCompleted;

  LibraryManga({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    this.url = '',
    this.type = 'Unknown',
    required this.addedAt,
    this.status = 'Unknown',
    this.isFavorite = false,
    this.lastReadChapter = 0.0,
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
    String type, {
    String status = "Reading",
  }) {
    return LibraryManga(
      id: id,
      title: title,
      author: author,
      imageUrl: imageUrl,
      url: url ?? '',
      type: type,
      addedAt: DateTime.now(),
      currentChapter: 0.0,
      currentPage: 0,
      totalPages: 0,
      isCompleted: false,
      status: status,
      isFavorite: false,
    );
  }

  factory LibraryManga.fromMap(Map<String, dynamic> map) {
    return LibraryManga(
      id: (map['mangaId'] ?? map['id']) as String,
      title: (map['mangaTitle'] ?? map['title']) as String,
      author: map['author'] as String? ?? 'Unknown',
      imageUrl: (map['mangaImageUrl'] ?? map['imageUrl']) as String? ?? '',
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? 'Manga',
      addedAt: _parseDate(map['addedAt']),
      status: map['status'] as String? ?? 'Reading',
      isFavorite: map['isFavorite'] as bool? ?? false,
      lastReadChapter: ((map['lastReadChapter'] ?? 0) as num).toDouble(),

      currentChapter: (map['currentChapter'] as num? ?? 0).toDouble(),
      currentPage: map['currentPage'] as int? ?? 1,
      totalPages: map['totalPages'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mangaId': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'url': url,
      'type': type,
      'addedAt': addedAt.toIso8601String(),
      'status': status,
      'isFavorite': isFavorite,
      'lastReadChapter': lastReadChapter,
      'currentChapter': currentChapter,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': isCompleted,
    };
  }

  Map<String, dynamic> toApiRequest() {
    return {
      'mangaId': id,
      'mangaTitle': title,
      'mangaImageUrl': imageUrl,
      'type': type,
      'status': status,
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
    String? localImageUrl,
    String? url,
    String? type,
    DateTime? addedAt,
    String? status,
    bool? isFavorite,
    double? lastReadChapter,
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
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadChapter: lastReadChapter ?? this.lastReadChapter,
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
