import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'device_state.dart';
import '../../../services/device_repository.dart';
import '../../../models/device_data.dart';
// import 'package:flutter/services.dart'; // Uncomment when using HapticFeedback

class DeviceCubit extends Cubit<DeviceState> {
  final DeviceRepository _repo;
  bool _prevFallDetected = false; // Theo dõi giá trị trước đó
  bool _isFirstSnapshot = true;  // Bỏ qua snapshot đầu tiên (dữ liệu cũ trên Firebase)

  DeviceCubit(this._repo) : super(DeviceState.loading()) {
    _repo.deviceStream.listen((data) {
      // Lưu lại state CŨ trước khi emit để tránh race condition
      final wasAlertActive = state.activeFallAlert;

      emit(state.copyWith(
        status: DeviceFetchStatus.success,
        deviceData: data,
      ));

      // Snapshot đầu tiên: chỉ đọc trạng thái hiện tại, KHÔNG kích hoạt cảnh báo
      if (_isFirstSnapshot) {
        _prevFallDetected = data.fallDetected;
        _isFirstSnapshot = false;
        print('[ACK] First snapshot ignored. fallDetected=${data.fallDetected}');
        return;
      }

      // Chỉ kích hoạt khi có chuyển trạng thái false → true (té ngã mới)
      final isNewFall = data.fallDetected && !_prevFallDetected;
      _prevFallDetected = data.fallDetected;

      if (isNewFall && !wasAlertActive) {
        if (!_repo.isFallAlertEnabled) {
          print('[ACK] Fall detected but alert is DISABLED in settings. Ignoring and NOT sending ACK. SMS will be sent by ESP32.');
          return;
        }

        print('[ACK] NEW fall detected! Sending ack_fall to Firebase...');
        _repo.sendFallAck().then((_) {
          print('[ACK] sendFallAck() completed successfully');
        }).catchError((e) {
          print('[ACK] sendFallAck() ERROR: $e');
        });
        _triggerFallAlert(data);
      }
    });
  }

  void _triggerFallAlert(DeviceData data) {
    // HapticFeedback.vibrate();
    emit(state.copyWith(activeFallAlert: true));
  }

  void dismissAlert() {
    emit(state.copyWith(activeFallAlert: false));
    // Reset trạng thái trên Firebase để lần sau không bị cảnh báo lại khi mở App
    _repo.resetFallStatus();
  }

  void toggleEmergencyMode(bool isEmergency) {
    _repo.setEmergencyMode(isEmergency);
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
