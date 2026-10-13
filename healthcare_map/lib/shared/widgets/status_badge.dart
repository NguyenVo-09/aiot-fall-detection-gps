import 'package:flutter/material.dart';
import '../../../models/device_data.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final DeviceStatus status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case DeviceStatus.online:
        bgColor = const Color(0xFFDCFCE7);
        textColor = AppColors.success;
        text = '● Online';
        break;
      case DeviceStatus.offline:
        bgColor = const Color(0xFFF3F4F6);
        textColor = AppColors.textSecondary;
        text = '● Offline';
        break;
      case DeviceStatus.fall:
        bgColor = const Color(0xFFFEE2E2);
        textColor = AppColors.danger;
        text = '⚠ Fall!';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
