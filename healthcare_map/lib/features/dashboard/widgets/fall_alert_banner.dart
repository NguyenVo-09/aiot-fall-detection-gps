import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/device_data.dart';

class FallAlertBanner extends StatelessWidget {
  final bool isVisible;
  final DeviceData? deviceData;
  final VoidCallback onViewDetails;

  const FallAlertBanner({
    Key? key,
    required this.isVisible,
    this.deviceData,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: isVisible ? 56.0 : 0.0,
      color: AppColors.danger,
      child: isVisible && deviceData != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phát hiện té ngã — ${DateFormatter.formatTime(deviceData!.timestamp)}',
                      style: AppTypography.alert,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Xem'),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
