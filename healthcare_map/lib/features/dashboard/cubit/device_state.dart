import 'package:equatable/equatable.dart';
import '../../../models/device_data.dart';

enum DeviceFetchStatus { initial, loading, success, failure }

class DeviceState extends Equatable {
  final DeviceFetchStatus status;
  final DeviceData? deviceData;
  final bool activeFallAlert;

  const DeviceState({
    this.status = DeviceFetchStatus.initial,
    this.deviceData,
    this.activeFallAlert = false,
  });

  factory DeviceState.loading() {
    return const DeviceState(status: DeviceFetchStatus.loading);
  }

  factory DeviceState.loaded(DeviceData data) {
    return DeviceState(status: DeviceFetchStatus.success, deviceData: data);
  }

  DeviceState copyWith({
    DeviceFetchStatus? status,
    DeviceData? deviceData,
    bool? activeFallAlert,
  }) {
    return DeviceState(
      status: status ?? this.status,
      deviceData: deviceData ?? this.deviceData,
      activeFallAlert: activeFallAlert ?? this.activeFallAlert,
    );
  }

  @override
  List<Object?> get props => [status, deviceData, activeFallAlert];
}
