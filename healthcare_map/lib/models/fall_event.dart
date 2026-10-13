import 'package:cloud_firestore/cloud_firestore.dart';

class FallEvent {
  final String id;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final int batteryAtEvent;

  const FallEvent({
    required this.id,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.batteryAtEvent,
  });

  /// Factory để tạo FallEvent từ Firestore document.
  ///
  /// Ưu tiên đọc trường [fall_time] (Firestore Timestamp do server tự ghi)
  /// để hiển thị đúng thời gian thực tế lúc xảy ra té ngã.
  factory FallEvent.fromFirestore(String docId, Map<String, dynamic> data) {
    DateTime ts;

    // Ưu tiên 1: fall_time — Firestore serverTimestamp, chính xác tuyệt đối
    final fallTime = data['fall_time'];
    if (fallTime is Timestamp) {
      ts = fallTime.toDate();
    } else if (data['timestamp'] != null) {
      // Fallback: nếu là lịch sử cũ (dùng biến timestamp kiểu int/double)
      // Dù uptime ESP32 sai số nhưng vẫn đỡ hơn là lấy DateTime.now()
      ts = DateTime.fromMillisecondsSinceEpoch((data['timestamp'] is num ? (data['timestamp'] as num).toInt() : 0) * 1000);
    } else {
      ts = DateTime.now();
    }

    return FallEvent(
      id: docId,
      timestamp: ts,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      batteryAtEvent: (data['battery_at_event'] as num?)?.toInt() ?? 0,
    );
  }
}
