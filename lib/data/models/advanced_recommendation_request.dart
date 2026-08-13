import 'dart:convert';

class AdvancedRecommendationRequest {
  final List<String> likedIds;
  final List<String> dislikedIds;
  final int limit;

  AdvancedRecommendationRequest({
    required this.likedIds,
    this.dislikedIds = const [],
    this.limit = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'likedIds': likedIds,
      'dislikedIds': dislikedIds,
      'limit': limit,
    };
  }

  factory AdvancedRecommendationRequest.fromMap(Map<String, dynamic> map) {
    return AdvancedRecommendationRequest(
      likedIds: List<String>.from(map['likedIds'] ?? []),
      dislikedIds: List<String>.from(map['dislikedIds'] ?? []),
      limit: map['limit']?.toInt() ?? 10,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdvancedRecommendationRequest.fromJson(String source) =>
      AdvancedRecommendationRequest.fromMap(json.decode(source));
}
