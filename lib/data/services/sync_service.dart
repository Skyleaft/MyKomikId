import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection.dart';
import 'manga_api_service.dart';

class SyncAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncAction.fromMap(Map<String, dynamic> map) {
    return SyncAction(
      id: map['id'] as String,
      type: map['type'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());
}

class SyncService {
  static const _syncQueueKey = 'sync_queue';
  bool _isSyncing = false;

  Future<void> enqueueAction(String type, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getStringList(_syncQueueKey) ?? [];
    
    final action = SyncAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );

    queueJson.add(action.toJson());
    await prefs.setStringList(_syncQueueKey, queueJson);
  }

  Future<void> syncPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList(_syncQueueKey) ?? [];
      if (queueJson.isEmpty) return;

      final List<String> remainingQueue = [];
      final apiService = getIt<MangaApiService>();

      for (var actionJson in queueJson) {
        final action = SyncAction.fromMap(jsonDecode(actionJson));
        bool success = false;

        try {
          switch (action.type) {
            case 'library_add':
              await apiService.addToUserLibrary(action.payload);
              success = true;
              break;
            case 'library_remove':
              await apiService.removeFromUserLibrary(action.payload['mangaId']);
              success = true;
              break;
            case 'progression_update':
              await apiService.updateUserProgression(action.payload);
              success = true;
              break;
          }
        } catch (e) {
          // If it's a network error, keep it in queue
          success = false;
        }

        if (!success) {
          remainingQueue.add(actionJson);
        }
      }

      await prefs.setStringList(_syncQueueKey, remainingQueue);
    } finally {
      _isSyncing = false;
    }
  }
}
