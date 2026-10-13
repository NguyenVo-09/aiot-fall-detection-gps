import 'dart:async';
import '../models/device_data.dart';
import '../models/fall_event.dart';

abstract class DeviceRepository {
  Stream<DeviceData> get deviceStream;
  Future<List<FallEvent>> getFallHistory();
  Stream<List<FallEvent>> getFallHistoryStream();

  /// Bật/Tắt chế độ khẩn cấp liên tục lấy GPS
  Future<void> setEmergencyMode(bool isEmergency);

  /// Gửi xác nhận đã nhận cảnh báo té ngã (ACK) lên Firebase
  Future<void> sendFallAck();

  /// Reset fall_detected và ack_fall về false sau khi người dùng hủy cảnh báo
  Future<void> resetFallStatus();

  /// Xóa một sự kiện té ngã theo ID trên Firestore
  Future<void> deleteFallEvent(String eventId);

  /// Trạng thái bật/tắt nhận cảnh báo té ngã từ phần cứng
  bool get isFallAlertEnabled;
  void setFallAlertEnabled(bool value);

  /// Ngưỡng cảnh báo pin (10–50%)
  double get batteryThreshold;
  void setBatteryThreshold(double value);
}
