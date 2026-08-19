class ChapterScrapingProgress {
  final String mangaId;
  final String mangaTitle;
  final String chapterId;
  final double chapterNumber;
  final int downloadedPages;
  final int totalPages;
  final int percent;
  final String status;

  const ChapterScrapingProgress({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterId,
    required this.chapterNumber,
    required this.downloadedPages,
    required this.totalPages,
    required this.percent,
    required this.status,
  });

  bool get isStarting => status.toLowerCase() == 'starting';
  bool get isInProgress => status.toLowerCase() == 'inprogress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory ChapterScrapingProgress.fromMap(Map<String, dynamic> map) {
    return ChapterScrapingProgress(
      mangaId: map['mangaId'] as String? ?? '',
      mangaTitle: map['mangaTitle'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      chapterNumber: (map['chapterNumber'] is num)
          ? (map['chapterNumber'] as num).toDouble()
          : double.tryParse(map['chapterNumber']?.toString() ?? '0') ?? 0.0,
      downloadedPages: (map['downloadedPages'] is num)
          ? (map['downloadedPages'] as num).toInt()
          : int.tryParse(map['downloadedPages']?.toString() ?? '0') ?? 0,
      totalPages: (map['totalPages'] is num)
          ? (map['totalPages'] as num).toInt()
          : int.tryParse(map['totalPages']?.toString() ?? '0') ?? 0,
      percent: (map['percent'] is num)
          ? (map['percent'] as num).toInt()
          : int.tryParse(map['percent']?.toString() ?? '0') ?? 0,
      status: map['status'] as String? ?? 'InProgress',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'chapterId': chapterId,
      'chapterNumber': chapterNumber,
      'downloadedPages': downloadedPages,
      'totalPages': totalPages,
      'percent': percent,
      'status': status,
    };
  }
}

class ChaptersUpdatedEvent {
  final String mangaId;
  final String mangaTitle;
  final String chapterId;
  final double chapterNumber;
  final int pageCount;

  const ChaptersUpdatedEvent({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterId,
    required this.chapterNumber,
    required this.pageCount,
  });

  factory ChaptersUpdatedEvent.fromMap(Map<String, dynamic> map) {
    return ChaptersUpdatedEvent(
      mangaId: map['mangaId'] as String? ?? '',
      mangaTitle: map['mangaTitle'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      chapterNumber: (map['chapterNumber'] is num)
          ? (map['chapterNumber'] as num).toDouble()
          : double.tryParse(map['chapterNumber']?.toString() ?? '0') ?? 0.0,
      pageCount: (map['pageCount'] is num)
          ? (map['pageCount'] as num).toInt()
          : int.tryParse(map['pageCount']?.toString() ?? '0') ?? 0,
    );
  }
}
