class MangaSummary {
  final String id;
  final int malId;
  final String title;
  final String author;
  final String type;
  final List<String>? genres;
  final String? description;
  final String? imageUrl;
  final String? localImageUrl;
  final double? rating;
  final int popularity;
  final int members;
  final String? status;
  final DateTime? releaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? url;
  final int totalView;
  final LatestChapterSummary? latestChapter;

  MangaSummary({
    required this.id,
    required this.malId,
    required this.title,
    required this.author,
    required this.type,
    this.genres,
    this.description,
    this.imageUrl,
    this.localImageUrl,
    this.rating,
    required this.popularity,
    required this.members,
    this.status,
    this.releaseDate,
    required this.createdAt,
    required this.updatedAt,
    this.url,
    required this.totalView,
    this.latestChapter,
  });

  factory MangaSummary.fromJson(Map<String, dynamic> json) {
    return MangaSummary(
      id: json['id'] as String,
      malId: json['malId'] as int? ?? 0,
      title: json['title'] as String,
      author: json['author'] as String,
      type: json['type'] as String,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      localImageUrl: json['localImageUrl'] as String?,
      rating: json['rating'] != null
          ? (json['rating'] as dynamic).toDouble()
          : null,
      popularity: json['popularity'] as int? ?? 0,
      members: json['members'] as int? ?? 0,
      status: json['status'] as String?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      url: json['url'] as String?,
      totalView: json['totalView'] as int? ?? 0,
      latestChapter: json['latestChapter'] != null
          ? LatestChapterSummary.fromJson(
              json['latestChapter'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String get displayImageUrl {
    if (localImageUrl != null && localImageUrl!.isNotEmpty) {
      // Assuming the base URL is the same as the API
      // We will handle the base URL in the service or configuration
      return localImageUrl!;
    }
    return imageUrl ?? '';
  }
}

class LatestChapterSummary {
  final String id;
  final double number;
  final int totalView;
  final DateTime uploadDate;
  final String? chapterProvider;
  final String? chapterProviderIcon;
  final int pageCount;
  final bool isChapterAvailable;

  LatestChapterSummary({
    required this.id,
    required this.number,
    required this.totalView,
    required this.uploadDate,
    this.chapterProvider,
    this.chapterProviderIcon,
    required this.pageCount,
    required this.isChapterAvailable,
  });

  factory LatestChapterSummary.fromJson(Map<String, dynamic> json) {
    return LatestChapterSummary(
      id: json['id'] as String,
      number: (json['number'] as num? ?? 0).toDouble(),
      totalView: json['totalView'] as int? ?? 0,
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'] as String)
          : DateTime.now(),
      chapterProvider: json['chapterProvider'] as String?,
      chapterProviderIcon: json['chapterProviderIcon'] as String?,
      pageCount: json['pageCount'] as int? ?? 0,
      isChapterAvailable: json['isChapterAvailable'] as bool? ?? true,
    );
  }
}
