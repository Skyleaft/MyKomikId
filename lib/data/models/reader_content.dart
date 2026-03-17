import 'manga_detail.dart';

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

  ReaderContent({
    required this.mangaId,
    required this.mangaTitle,
    required this.currentChapterNumber,
    required this.chapterId,
    required this.allChapters,
    required this.chapterTitle,
    required this.pageUrls,
    this.currentPage = 1,
  }) : totalPages = pageUrls.length;

  // Factory constructor to create from map
  factory ReaderContent.fromMap(Map<String, dynamic> map) {
    return ReaderContent(
      mangaId: map['mangaId'] as String,
      mangaTitle: map['mangaTitle'] as String,
      currentChapterNumber: (map['currentChapterNumber'] as num? ?? 0)
          .toDouble(),
      chapterId: map['chapterId'] as String? ?? "",
      allChapters:
          (map['allChapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      chapterTitle: map['chapterTitle'] as String,
      pageUrls:
          (map['pageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentPage: map['currentPage'] as int? ?? 1,
    );
  }
}
