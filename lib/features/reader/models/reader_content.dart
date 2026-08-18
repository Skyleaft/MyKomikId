import '../../manga_detail/models/manga_detail.dart';
import '../../history/models/progression.dart';

class ReaderContent {
  final String mangaId;
  final String mangaTitle;
  final double currentChapterNumber;
  final List<Chapter> allChapters;
  final String chapterId;
  final String chapterTitle;
  final List<String> pageUrls;
  final int currentPage;
  final int totalPages;
  final MangaProgression? progression;
  final Map<String, String>? httpHeaders;

  ReaderContent({
    required this.mangaId,
    required this.mangaTitle,
    required this.currentChapterNumber,
    required this.chapterId,
    required this.allChapters,
    required this.chapterTitle,
    required this.pageUrls,
    this.currentPage = 1,
    this.progression,
    this.httpHeaders,
  }) : totalPages = pageUrls.length;

  ReaderContent copyWith({
    String? mangaId,
    String? mangaTitle,
    double? currentChapterNumber,
    List<Chapter>? allChapters,
    String? chapterId,
    String? chapterTitle,
    List<String>? pageUrls,
    int? currentPage,
    MangaProgression? progression,
    Map<String, String>? httpHeaders,
  }) {
    return ReaderContent(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      currentChapterNumber: currentChapterNumber ?? this.currentChapterNumber,
      allChapters: allChapters ?? this.allChapters,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      pageUrls: pageUrls ?? this.pageUrls,
      currentPage: currentPage ?? this.currentPage,
      progression: progression ?? this.progression,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }

  factory ReaderContent.fromMap(Map<String, dynamic> map) {
    final rawPages =
        map['pageUrls'] as List<dynamic>? ?? map['pages'] as List<dynamic>?;
    final List<String> pagesList =
        rawPages?.map((e) => e as String).toList() ?? [];

    Map<String, String>? headers;
    if (map['httpHeaders'] is Map) {
      headers = (map['httpHeaders'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else if (map['headers'] is Map) {
      headers = (map['headers'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return ReaderContent(
      mangaId: map['mangaId'] as String? ?? '',
      mangaTitle: map['mangaTitle'] as String? ?? '',
      currentChapterNumber:
          (map['currentChapterNumber'] as num? ?? map['number'] as num? ?? 0)
              .toDouble(),
      chapterId: map['chapterId'] as String? ?? map['id'] as String? ?? "",
      allChapters: (map['allChapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      chapterTitle:
          map['chapterTitle'] as String? ?? map['title'] as String? ?? '',
      pageUrls: pagesList,
      currentPage: map['currentPage'] as int? ?? 1,
      httpHeaders: headers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'currentChapterNumber': currentChapterNumber,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'pageUrls': pageUrls,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'httpHeaders': httpHeaders,
    };
  }
}
