import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/device_data.dart';
import '../../../models/fall_event.dart';
import '../../../services/device_repository.dart';
import 'package:get_it/get_it.dart';
import '../cubit/device_cubit.dart';
import '../cubit/device_state.dart';
import '../widgets/device_status_card.dart';
import '../widgets/fall_alert_banner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../main/view/main_wrapper.dart';
import '../../map/widgets/esp_marker.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _showFallDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 32),
                const SizedBox(width: 12),
                Text('TÉ NGÃ PHÁT HIỆN', style: AppTypography.display.copyWith(color: AppColors.danger)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Vui lòng kiểm tra ứng dụng Bản Đồ để biết vị trí chi tiết.', style: AppTypography.body),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<DeviceCubit>().dismissAlert();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Đã hiểu & Đóng cảnh báo', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) {
        final device = state.deviceData;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.3),
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text('Healthcare Map', style: AppTypography.display.copyWith(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          body: Column(
            children: [
              FallAlertBanner(
                isVisible: state.activeFallAlert,
                deviceData: device,
                onViewDetails: () => _showFallDetails(context),
              ),
              Expanded(
                child: state.status == DeviceFetchStatus.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : device == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.devices_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text('Chưa kết nối thiết bị', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {},
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                              children: [
                                DeviceStatusCard(device: device),
                                const SizedBox(height: 20),
                                _buildQuickInfoRow(device),
                                const SizedBox(height: 20),
                                _buildMiniMap(context, device),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickInfoRow(device) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF075494)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('VỊ TRÍ ESP32', style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  Text('${device.lat}°N', style: AppTypography.data.copyWith(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${device.lng}°E', style: AppTypography.data.copyWith(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StreamBuilder<List<FallEvent>>(
              stream: GetIt.I<DeviceRepository>().getFallHistoryStream(),
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];
                final today = DateTime.now();
                final fallsToday = events.where((e) => 
                  e.timestamp.year == today.year &&
                  e.timestamp.month == today.month &&
                  e.timestamp.day == today.day
                ).length;

                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF075494)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'TÉ NGÃ HÔM NAY', 
                              style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.9)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$fallsToday', style: AppTypography.display.copyWith(color: Colors.white, fontSize: 28)),
                          const SizedBox(width: 6),
                          Text('lần', style: AppTypography.body.copyWith(color: Colors.white.withOpacity(0.9))),
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap(BuildContext context, DeviceData? device) {
    final espLatLng = device != null 
        ? LatLng(device.lat, device.lng) 
        : const LatLng(10.7769, 106.7009);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('BẢN ĐỒ NHANH', style: AppTypography.heading.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            height: 200,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: espLatLng,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Disable interactions on mini map
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: espLatLng,
                            width: 60,
                            height: 60,
                            child: const EspMarkerWidget(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        MainWrapper.navigateToTab(context, 1); // 1 = Map tab
                      }, 
                      icon: const Icon(Icons.open_in_full, size: 16),
                      label: const Text('Xem toàn màn hình'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
