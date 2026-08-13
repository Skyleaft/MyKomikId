import 'manga_summary.dart';

class SearchResult {
  final String title;
  final String detailUrl;
  final String thumbnail;
  final String type;
  final String genre;
  final String lastUpdateText;
  final double latestChapterNumber;
  final DateTime? latestScrapped;
  final String? mangaId;
  final double? currentChapterNumber;

  SearchResult({
    required this.title,
    required this.detailUrl,
    required this.thumbnail,
    required this.type,
    required this.genre,
    required this.lastUpdateText,
    required this.latestChapterNumber,
    this.latestScrapped,
    this.mangaId,
    this.currentChapterNumber,
  });

  factory SearchResult.fromMangaSummary(MangaSummary summary) {
    final genresText = summary.genres != null && summary.genres!.isNotEmpty
        ? summary.genres!.join(', ')
        : 'Unknown';
    return SearchResult(
      title: summary.title,
      detailUrl: summary.url ?? '',
      thumbnail: summary.displayImageUrl,
      type: summary.type,
      genre: genresText,
      lastUpdateText: summary.latestChapter != null
          ? 'Ch. ${summary.latestChapter!.number}'
          : 'N/A',
      latestChapterNumber: summary.latestChapter?.number ?? 0.0,
      latestScrapped: summary.updatedAt,
      mangaId: summary.id,
    );
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      detailUrl: json['detailUrl'] as String? ?? json['url'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? json['imageUrl'] as String? ?? '',
      type: json['type'] as String? ?? '',
      genre: json['genre'] as String? ?? (json['genres'] is List ? (json['genres'] as List).join(', ') : ''),
      lastUpdateText: json['lastUpdateText'] as String? ?? '',
      latestChapterNumber: (json['latestChapterNumber'] as num? ?? 0).toDouble(),
      latestScrapped: json['latestScrapped'] != null
          ? DateTime.tryParse(json['latestScrapped'] as String)
          : null,
      mangaId: json['mangaId'] as String? ?? json['id'] as String?,
      currentChapterNumber: (json['currentChapterNumber'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'detailUrl': detailUrl,
      'thumbnail': thumbnail,
      'type': type,
      'genre': genre,
      'lastUpdateText': lastUpdateText,
      'latestChapterNumber': latestChapterNumber,
      'latestScrapped': latestScrapped?.toIso8601String(),
      'mangaId': mangaId,
      'currentChapterNumber': currentChapterNumber,
    };
  }
}
