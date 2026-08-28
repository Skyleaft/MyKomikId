import 'dart:convert';

class MangaSortOption {
  final String field;
  final String direction;

  const MangaSortOption({
    required this.field,
    this.direction = 'desc',
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'direction': direction,
    };
  }

  factory MangaSortOption.fromMap(Map<String, dynamic> map) {
    return MangaSortOption(
      field: map['field'] as String? ?? 'updatedAt',
      direction: map['direction'] as String? ?? 'desc',
    );
  }

  String toJson() => json.encode(toMap());

  factory MangaSortOption.fromJson(String source) =>
      MangaSortOption.fromMap(json.decode(source) as Map<String, dynamic>);

  MangaSortOption copyWith({
    String? field,
    String? direction,
  }) {
    return MangaSortOption(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MangaSortOption &&
        other.field == field &&
        other.direction == direction;
  }

  @override
  int get hashCode => field.hashCode ^ direction.hashCode;
}

class MangaAdvancedFilter {
  final String? search;
  final List<String> includedGenres;
  final String? genreMatchMode; // 'and', 'or', 'all', 'any'
  final List<String> excludedGenres;
  final List<String> statuses;
  final List<String> types;
  final String? author;
  final double? minRating;
  final double? maxRating;
  final int? minPopularity;
  final int? maxPopularity;
  final int? minTotalView;
  final int? maxTotalView;
  final int? minChapters;
  final int? maxChapters;
  final DateTime? startReleaseDate;
  final DateTime? endReleaseDate;
  final bool? nsfw;
  final int? anilistId;
  final bool? unlinkedAnilist;

  const MangaAdvancedFilter({
    this.search,
    this.includedGenres = const [],
    this.genreMatchMode,
    this.excludedGenres = const [],
    this.statuses = const [],
    this.types = const [],
    this.author,
    this.minRating,
    this.maxRating,
    this.minPopularity,
    this.maxPopularity,
    this.minTotalView,
    this.maxTotalView,
    this.minChapters,
    this.maxChapters,
    this.startReleaseDate,
    this.endReleaseDate,
    this.nsfw = false,
    this.anilistId,
    this.unlinkedAnilist,
  });

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      includedGenres.isNotEmpty ||
      excludedGenres.isNotEmpty ||
      statuses.isNotEmpty ||
      types.isNotEmpty ||
      (author != null && author!.trim().isNotEmpty) ||
      minRating != null ||
      maxRating != null ||
      minPopularity != null ||
      maxPopularity != null ||
      minTotalView != null ||
      maxTotalView != null ||
      minChapters != null ||
      maxChapters != null ||
      startReleaseDate != null ||
      endReleaseDate != null ||
      (nsfw != null && nsfw != false) ||
      anilistId != null ||
      unlinkedAnilist != null;

  int get activeFiltersCount {
    int count = 0;
    if (includedGenres.isNotEmpty) count += includedGenres.length;
    if (excludedGenres.isNotEmpty) count += excludedGenres.length;
    if (statuses.isNotEmpty) count += statuses.length;
    if (types.isNotEmpty) count += types.length;
    if (author != null && author!.trim().isNotEmpty) count++;
    if (minRating != null || maxRating != null) count++;
    if (minChapters != null || maxChapters != null) count++;
    if (minTotalView != null || maxTotalView != null) count++;
    if (minPopularity != null || maxPopularity != null) count++;
    if (startReleaseDate != null || endReleaseDate != null) count++;
    if (nsfw != null && nsfw != false) count++;
    if (unlinkedAnilist != null) count++;
    return count;
  }

  Map<String, dynamic> toMap() {
    return {
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (includedGenres.isNotEmpty) 'includedGenres': includedGenres,
      if (genreMatchMode != null && genreMatchMode!.isNotEmpty)
        'genreMatchMode': genreMatchMode,
      if (excludedGenres.isNotEmpty) 'excludedGenres': excludedGenres,
      if (statuses.isNotEmpty) 'statuses': statuses,
      if (types.isNotEmpty) 'types': types,
      if (author != null && author!.trim().isNotEmpty) 'author': author!.trim(),
      if (minRating != null) 'minRating': minRating,
      if (maxRating != null) 'maxRating': maxRating,
      if (minPopularity != null) 'minPopularity': minPopularity,
      if (maxPopularity != null) 'maxPopularity': maxPopularity,
      if (minTotalView != null) 'minTotalView': minTotalView,
      if (maxTotalView != null) 'maxTotalView': maxTotalView,
      if (minChapters != null) 'minChapters': minChapters,
      if (maxChapters != null) 'maxChapters': maxChapters,
      if (startReleaseDate != null)
        'startReleaseDate': startReleaseDate!.toIso8601String(),
      if (endReleaseDate != null)
        'endReleaseDate': endReleaseDate!.toIso8601String(),
      if (nsfw != null) 'nsfw': nsfw,
      if (anilistId != null) 'anilistId': anilistId,
      if (unlinkedAnilist != null) 'unlinkedAnilist': unlinkedAnilist,
    };
  }

  factory MangaAdvancedFilter.fromMap(Map<String, dynamic> map) {
    return MangaAdvancedFilter(
      search: map['search'] as String?,
      includedGenres: List<String>.from(map['includedGenres'] ?? []),
      genreMatchMode: map['genreMatchMode'] as String?,
      excludedGenres: List<String>.from(map['excludedGenres'] ?? []),
      statuses: List<String>.from(map['statuses'] ?? []),
      types: List<String>.from(map['types'] ?? []),
      author: map['author'] as String?,
      minRating: (map['minRating'] as num?)?.toDouble(),
      maxRating: (map['maxRating'] as num?)?.toDouble(),
      minPopularity: (map['minPopularity'] as num?)?.toInt(),
      maxPopularity: (map['maxPopularity'] as num?)?.toInt(),
      minTotalView: (map['minTotalView'] as num?)?.toInt(),
      maxTotalView: (map['maxTotalView'] as num?)?.toInt(),
      minChapters: (map['minChapters'] as num?)?.toInt(),
      maxChapters: (map['maxChapters'] as num?)?.toInt(),
      startReleaseDate: map['startReleaseDate'] != null
          ? DateTime.tryParse(map['startReleaseDate'] as String)
          : null,
      endReleaseDate: map['endReleaseDate'] != null
          ? DateTime.tryParse(map['endReleaseDate'] as String)
          : null,
      nsfw: map['nsfw'] as bool?,
      anilistId: (map['anilistId'] as num?)?.toInt(),
      unlinkedAnilist: map['unlinkedAnilist'] as bool?,
    );
  }

  String toJson() => json.encode(toMap());

  factory MangaAdvancedFilter.fromJson(String source) =>
      MangaAdvancedFilter.fromMap(json.decode(source) as Map<String, dynamic>);

  MangaAdvancedFilter copyWith({
    String? search,
    List<String>? includedGenres,
    String? genreMatchMode,
    List<String>? excludedGenres,
    List<String>? statuses,
    List<String>? types,
    String? author,
    double? minRating,
    double? maxRating,
    int? minPopularity,
    int? maxPopularity,
    int? minTotalView,
    int? maxTotalView,
    int? minChapters,
    int? maxChapters,
    DateTime? startReleaseDate,
    DateTime? endReleaseDate,
    bool? nsfw,
    int? anilistId,
    bool? unlinkedAnilist,
    bool clearSearch = false,
    bool clearAuthor = false,
    bool clearMinRating = false,
    bool clearMaxRating = false,
    bool clearMinChapters = false,
    bool clearMaxChapters = false,
    bool clearNsfw = false,
  }) {
    return MangaAdvancedFilter(
      search: clearSearch ? null : (search ?? this.search),
      includedGenres: includedGenres ?? this.includedGenres,
      genreMatchMode: genreMatchMode ?? this.genreMatchMode,
      excludedGenres: excludedGenres ?? this.excludedGenres,
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      author: clearAuthor ? null : (author ?? this.author),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxRating: clearMaxRating ? null : (maxRating ?? this.maxRating),
      minPopularity: minPopularity ?? this.minPopularity,
      maxPopularity: maxPopularity ?? this.maxPopularity,
      minTotalView: minTotalView ?? this.minTotalView,
      maxTotalView: maxTotalView ?? this.maxTotalView,
      minChapters: clearMinChapters ? null : (minChapters ?? this.minChapters),
      maxChapters: clearMaxChapters ? null : (maxChapters ?? this.maxChapters),
      startReleaseDate: startReleaseDate ?? this.startReleaseDate,
      endReleaseDate: endReleaseDate ?? this.endReleaseDate,
      nsfw: clearNsfw ? null : (nsfw ?? this.nsfw),
      anilistId: anilistId ?? this.anilistId,
      unlinkedAnilist: unlinkedAnilist ?? this.unlinkedAnilist,
    );
  }
}

class QueryPagedMangaRequest {
  final MangaAdvancedFilter? filter;
  final List<MangaSortOption>? sorts;
  final int page;
  final int pageSize;

  const QueryPagedMangaRequest({
    this.filter,
    this.sorts,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toMap() {
    return {
      if (filter != null) 'filter': filter!.toMap(),
      if (sorts != null && sorts!.isNotEmpty)
        'sorts': sorts!.map((s) => s.toMap()).toList(),
      'page': page,
      'pageSize': pageSize,
    };
  }

  factory QueryPagedMangaRequest.fromMap(Map<String, dynamic> map) {
    return QueryPagedMangaRequest(
      filter: map['filter'] != null
          ? MangaAdvancedFilter.fromMap(map['filter'] as Map<String, dynamic>)
          : null,
      sorts: map['sorts'] != null
          ? (map['sorts'] as List<dynamic>)
              .map((e) => MangaSortOption.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  String toJson() => json.encode(toMap());

  factory QueryPagedMangaRequest.fromJson(String source) =>
      QueryPagedMangaRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  QueryPagedMangaRequest copyWith({
    MangaAdvancedFilter? filter,
    List<MangaSortOption>? sorts,
    int? page,
    int? pageSize,
  }) {
    return QueryPagedMangaRequest(
      filter: filter ?? this.filter,
      sorts: sorts ?? this.sorts,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
