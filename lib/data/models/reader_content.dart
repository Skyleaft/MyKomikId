import 'manga_detail.dart';
import 'progression.dart';

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
  }) : totalPages = pageUrls.length;

  factory ReaderContent.fromMap(Map<String, dynamic> map) {
    final rawPages = map['pageUrls'] as List<dynamic>? ?? map['pages'] as List<dynamic>?;
    final List<String> pagesList = rawPages?.map((e) => e as String).toList() ?? [];

    return ReaderContent(
      mangaId: map['mangaId'] as String? ?? '',
      mangaTitle: map['mangaTitle'] as String? ?? '',
      currentChapterNumber: (map['currentChapterNumber'] as num? ?? map['number'] as num? ?? 0)
          .toDouble(),
      chapterId: map['chapterId'] as String? ?? map['id'] as String? ?? "",
      allChapters: (map['allChapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      chapterTitle: map['chapterTitle'] as String? ?? map['title'] as String? ?? '',
      pageUrls: pagesList,
      currentPage: map['currentPage'] as int? ?? 1,
    );
  }
}
