import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model satu item notifikasi.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// Service sederhana untuk menyimpan riwayat notifikasi secara lokal
/// (SharedPreferences). Notifikasi disimpan sebagai list JSON di bawah
/// satu key, terbaru di urutan paling awal.
class NotificationService {
  static const String _storageKey = 'app_notifications';

  /// Tambahkan notifikasi baru ke riwayat (otomatis ditandai belum dibaca).
  static Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getAll();

    final newNotification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
    );

    notifications.insert(0, newNotification);

    await _saveAll(prefs, notifications);
  }

  /// Ambil seluruh riwayat notifikasi, terbaru di awal.
  static Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Jumlah notifikasi yang belum dibaca (untuk badge).
  static Future<int> getUnreadCount() async {
    final notifications = await getAll();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Tandai satu notifikasi sebagai sudah dibaca.
  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getAll();

    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      await _saveAll(prefs, notifications);
    }
  }

  /// Tandai semua notifikasi sebagai sudah dibaca.
  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getAll();

    for (final n in notifications) {
      n.isRead = true;
    }
    await _saveAll(prefs, notifications);
  }

  /// Hapus satu notifikasi dari riwayat.
  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getAll();

    notifications.removeWhere((n) => n.id == id);
    await _saveAll(prefs, notifications);
  }

  /// Hapus seluruh riwayat notifikasi.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _saveAll(
    SharedPreferences prefs,
    List<AppNotification> notifications,
  ) async {
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}