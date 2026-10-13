import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_data.dart';
import '../models/fall_event.dart';

import 'device_repository.dart';

/// Repository kết nối thực tế với Cloud Firestore.
/// Lắng nghe real-time document /devices/ESP32_FALL_001
/// và đọc lịch sử từ collection /fall_events.
class FirebaseDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _deviceId = 'ESP32_FALL_001';
  bool _isFallAlertEnabled = true;
  double _batteryThreshold = 20.0;

  @override
  bool get isFallAlertEnabled => _isFallAlertEnabled;

  @override
  void setFallAlertEnabled(bool value) {
    _isFallAlertEnabled = value;
  }

  @override
  double get batteryThreshold => _batteryThreshold;

  @override
  void setBatteryThreshold(double value) {
    _batteryThreshold = value;
  }

  @override
  Stream<DeviceData> get deviceStream {
    return _db
        .collection('devices')
        .doc(_deviceId)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) {
            return const DeviceData(
              deviceId: _deviceId,
              timestamp: 0,
              fallDetected: false,
              lat: 0.0,
              lng: 0.0,
              gpsAccuracy: 0.0,
              batteryPct: 0,
              rssi: 0,
            );
          }
          return DeviceData.fromFirestore(snap.data()!);
        });
  }

  @override
  Future<List<FallEvent>> getFallHistory() async {
    try {
      final snap = await _db
          .collection('fall_events')
          .orderBy('fall_time', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .where((doc) => doc.data()['device_id'] == _deviceId)
          .map((doc) => FallEvent.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<FallEvent>> getFallHistoryStream() {
    return _db
        .collection('fall_events')
        .orderBy('fall_time', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['device_id'] == _deviceId)
          .map((doc) => FallEvent.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<void> setEmergencyMode(bool isEmergency) async {
    try {
      await _db.collection('devices').doc(_deviceId).set(
        {'emergency_mode': isEmergency},
        SetOptions(merge: true),
      );
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  @override
  Future<void> sendFallAck() async {
    try {
      await _db.collection('devices').doc(_deviceId).set(
        {'ack_fall': true},
        SetOptions(merge: true),
      );
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  @override
  Future<void> resetFallStatus() async {
    try {
      await _db.collection('devices').doc(_deviceId).update({
        'fall_detected': false,
      });
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  @override
  Future<void> deleteFallEvent(String eventId) async {
    try {
      await _db.collection('fall_events').doc(eventId).delete();
    } catch (e) {
      // Bỏ qua lỗi
    }
  }
}
