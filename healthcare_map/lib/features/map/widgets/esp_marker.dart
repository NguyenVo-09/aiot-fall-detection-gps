import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EspMarkerWidget extends StatefulWidget {
  const EspMarkerWidget({Key? key}) : super(key: key);

  @override
  State<EspMarkerWidget> createState() => _EspMarkerWidgetState();
}

class _EspMarkerWidgetState extends State<EspMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final value = _pulseController.value;
            return Container(
              width: 20 + (value * 40),
              height: 20 + (value * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.5 - (value * 0.5)),
              ),
            );
          },
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.sensors, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}
