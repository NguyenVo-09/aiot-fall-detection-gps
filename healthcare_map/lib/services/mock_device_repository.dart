import 'dart:async';
import '../models/device_data.dart';
import '../models/fall_event.dart';

import 'device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  final _controller = StreamController<DeviceData>.broadcast();
  Timer? _timer;
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
  Future<void> deleteFallEvent(String eventId) async {
    // Không làm gì trong mock
  }

  MockDeviceRepository() {
    _startMockStream();
  }

  void _startMockStream() {
    // Giả lập nhận dữ liệu mỗi 5 giây
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Giả lập trạng thái té ngã (10% cơ hội)
      final isFall = (timer.tick % 10) == 0;

      final data = DeviceData(
        deviceId: 'ESP32_001',
        timestamp: now,
        fallDetected: isFall,
        lat: 10.7769 + (timer.tick * 0.0001), // Giả lập di chuyển nhẹ
        lng: 106.7009 + (timer.tick * 0.0001),
        gpsAccuracy: 5.0,
        batteryPct: 100 - (timer.tick % 100), // Pin giảm dần
        rssi: -65,
      );
      _controller.add(data);
    });
  }

  @override
  Stream<DeviceData> get deviceStream => _controller.stream;

  @override
  Future<List<FallEvent>> getFallHistory() async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập delay mạng
    return [
      FallEvent(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        lat: 10.77692,
        lng: 106.70091,
        batteryAtEvent: 73,
      ),
      FallEvent(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        lat: 10.78012,
        lng: 106.69985,
        batteryAtEvent: 85,
      ),
    ];
  }

  @override
  Stream<List<FallEvent>> getFallHistoryStream() {
    return Stream.value([
      FallEvent(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        lat: 10.77692,
        lng: 106.70091,
        batteryAtEvent: 73,
      ),
      FallEvent(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        lat: 10.78012,
        lng: 106.69985,
        batteryAtEvent: 85,
      ),
    ]);
  }

  @override
  Future<void> sendFallAck() async {
    // Không làm gì cả trong mock
  }

  @override
  Future<void> resetFallStatus() async {
    // Không làm gì cả trong mock
  }
  @override
  Future<void> setEmergencyMode(bool isEmergency) async {
    // Không làm gì cho mock
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
