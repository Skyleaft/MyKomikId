import 'dart:convert';
import '../../../core/models/manga_summary.dart';

class LibraryManga {
  final String id;
  final String userLibraryId;
  final String title;
  final String author;
  final String imageUrl;
  final String url;
  final String type;
  final DateTime addedAt;
  final DateTime updatedAt;

  final String status;
  final bool isFavorite;
  final double lastReadChapter;

  final double currentChapter;
  final int currentPage;
  final int totalPages;
  final bool isCompleted;

  LibraryManga({
    required this.id,
    this.userLibraryId = '',
    required this.title,
    required this.author,
    required this.imageUrl,
    this.url = '',
    this.type = 'Unknown',
    required this.addedAt,
    DateTime? updatedAt,
    this.status = 'Reading',
    this.isFavorite = false,
    this.lastReadChapter = 0.0,
    required this.currentChapter,
    required this.currentPage,
    required this.totalPages,
    required this.isCompleted,
  }) : updatedAt = updatedAt ?? addedAt;

  factory LibraryManga.fromMangaDetail(
    String id,
    String title,
    String author,
    String imageUrl,
    String? url,
    String type, {
    String status = "Reading",
  }) {
    final now = DateTime.now();
    return LibraryManga(
      id: id,
      title: title,
      author: author,
      imageUrl: imageUrl,
      url: url ?? '',
      type: type,
      addedAt: now,
      updatedAt: now,
      currentChapter: 0.0,
      currentPage: 0,
      totalPages: 0,
      isCompleted: false,
      status: status,
      isFavorite: false,
    );
  }

  factory LibraryManga.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? mangaObj;
    if (map['manga'] != null && map['manga'] is Map<String, dynamic>) {
      mangaObj = map['manga'] as Map<String, dynamic>;
    }

    final mangaSummary = mangaObj != null ? MangaSummary.fromJson(mangaObj) : null;

    final mangaId = map['mangaId'] as String? ??
        mangaSummary?.id ??
        map['id'] as String? ??
        '';

    final userLibId = (map['id'] as String? ?? '').isNotEmpty && mangaObj != null
        ? (map['id'] as String)
        : (map['userLibraryId'] as String? ?? '');

    final title = mangaSummary?.title ??
        map['mangaTitle'] as String? ??
        map['title'] as String? ??
        'Unknown';

    final author = mangaSummary?.author ??
        map['author'] as String? ??
        'Unknown';

    final imageUrl = mangaSummary?.displayImageUrl ??
        map['mangaImageUrl'] as String? ??
        map['imageUrl'] as String? ??
        '';

    final url = mangaSummary?.url ?? map['url'] as String? ?? '';
    final type = mangaSummary?.type ?? map['type'] as String? ?? 'Manga';

    return LibraryManga(
      id: mangaId,
      userLibraryId: userLibId,
      title: title,
      author: author,
      imageUrl: imageUrl,
      url: url,
      type: type,
      addedAt: _parseDate(map['addedAt']),
      updatedAt: _parseDate(map['updatedAt']),
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
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userLibraryId': userLibraryId,
      'mangaId': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'url': url,
      'type': type,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'isFavorite': isFavorite,
      'lastReadChapter': lastReadChapter,
      'currentChapter': currentChapter,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': isCompleted,
    };
  }

  Map<String, dynamic> toApiRequest([String userId = '']) {
    return {
      'userId': userId,
      'mangaId': id,
      'status': status,
      'isFavorite': isFavorite,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory LibraryManga.fromJson(String source) =>
      LibraryManga.fromMap(jsonDecode(source) as Map<String, dynamic>);

  LibraryManga copyWith({
    String? id,
    String? userLibraryId,
    String? title,
    String? author,
    String? imageUrl,
    String? localImageUrl,
    String? url,
    String? type,
    DateTime? addedAt,
    DateTime? updatedAt,
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
      userLibraryId: userLibraryId ?? this.userLibraryId,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
