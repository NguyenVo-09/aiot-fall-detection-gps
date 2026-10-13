import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../cubit/device_cubit.dart';
import '../../../models/device_data.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../services/device_repository.dart';
import 'battery_indicator.dart';

class DeviceStatusCard extends StatelessWidget {
  final DeviceData device;

  const DeviceStatusCard({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFall = device.status == DeviceStatus.fall;
    final isOffline = device.status == DeviceStatus.offline;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFall 
              ? [AppColors.danger, const Color(0xFF991B1B)]
              : [AppColors.primary, const Color(0xFF075494)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isFall ? AppColors.danger.withOpacity(0.4) : AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(status: device.status),
                const Spacer(),
                BatteryIndicator(
                  percent: device.batteryPct,
                  threshold: GetIt.I<DeviceRepository>().batteryThreshold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.watch, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              device.deviceId,
                              style: AppTypography.heading.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Cập nhật: ${DateFormatter.formatTime(device.timestamp)}',
                              style: AppTypography.caption.copyWith(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (device.emergencyMode)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Khẩn cấp ĐANG BẬT',
                            style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_circle, color: Colors.white),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Tắt khẩn cấp',
                          onPressed: () {
                            context.read<DeviceCubit>().toggleEmergencyMode(false);
                          },
                        )
                      ],
                    ),
                  )
                else
                  Tooltip(
                    message: isOffline ? 'Thiết bị đang offline' : 'Bật theo dõi liên tục',
                    child: ElevatedButton.icon(
                      onPressed: isOffline ? null : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận Khẩn cấp'),
                            content: const Text('Bạn có chắc chắn muốn bật chế độ định vị khẩn cấp liên tục không? Việc này sẽ tiêu tốn pin rất nhanh.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<DeviceCubit>().toggleEmergencyMode(true);
                                },
                                child: const Text('BẬT'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.warning_amber, size: 16, color: Colors.black),
                      label: const Text('Khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white.withOpacity(0.8), // Keep it white even when disabled
                        disabledForegroundColor: Colors.black54, // Dark text when disabled
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
