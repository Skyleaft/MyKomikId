class SearchResult {
  final String title;
  final String detailUrl;
  final String thumbnail;
  final String type;
  final String genre;
  final String lastUpdateText;
  final double latestChapterNumber;
  final DateTime? latestScrapped;

  SearchResult({
    required this.title,
    required this.detailUrl,
    required this.thumbnail,
    required this.type,
    required this.genre,
    required this.lastUpdateText,
    required this.latestChapterNumber,
    this.latestScrapped,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      detailUrl: json['detailUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      type: json['type'] ?? '',
      genre: json['genre'] ?? '',
      lastUpdateText: json['lastUpdateText'] ?? '',
      latestChapterNumber: (json['latestChapterNumber'] as num? ?? 0)
          .toDouble(),
      latestScrapped: json['latestScrapped'] != null
          ? DateTime.parse(json['latestScrapped'] as String)
          : null,
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
    };
  }
}
