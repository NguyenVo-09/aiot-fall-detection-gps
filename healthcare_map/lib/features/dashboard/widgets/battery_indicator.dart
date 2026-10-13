import 'package:flutter/material.dart';
import '../../../core/constants/app_typography.dart';

class BatteryIndicator extends StatelessWidget {
  final int percent;
  final double threshold;

  const BatteryIndicator({Key? key, required this.percent, this.threshold = 20.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isBelowThreshold = percent < threshold && percent > 0;

    IconData iconData;
    if (percent > 60) {
      iconData = Icons.battery_full;
    } else if (percent >= 20) {
      iconData = Icons.battery_4_bar;
    } else {
      iconData = Icons.battery_alert;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge cảnh báo pin thấp
        if (isBelowThreshold)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 3),
                Text(
                  'PIN THẤP',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Icon(iconData, color: Colors.white, size: 20),
        const SizedBox(width: 4),
        Text(
          '$percent%',
          style: AppTypography.data.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
