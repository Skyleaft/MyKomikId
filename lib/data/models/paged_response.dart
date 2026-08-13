class PagedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.totalPages = 1,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PagedResponse(
      items: itemsList,
      totalCount: json['totalCount'] as int? ?? itemsList.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}
