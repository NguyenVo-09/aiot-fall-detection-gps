import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';
import '../../dashboard/cubit/device_cubit.dart';
import '../../dashboard/cubit/device_state.dart';
import '../widgets/esp_marker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  void _showDeviceDetails(BuildContext context, device, LatLng phoneLatLng) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sensors, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(device.deviceId, style: AppTypography.heading),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('📍 ${device.lat}°N, ${device.lng}°E', style: AppTypography.data),
            const SizedBox(height: 8),
            Text('⏱ Cập nhật: ${DateFormatter.formatTime(device.timestamp)}',
                style: AppTypography.body),
            const SizedBox(height: 8),
            Text('🔋 Pin: ${device.batteryPct}%  •  RSSI: ${device.rssi} dBm',
                style: AppTypography.body),
            const SizedBox(height: 8),
            Text('Chính xác GPS: ±${device.gpsAccuracy}m', style: AppTypography.body),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final espLatLng = LatLng(device.lat, device.lng);
                      // Đóng bottom sheet trước
                      Navigator.pop(sheetContext);
                      // Gọi API OSRM lấy tuyến đường
                      context.read<MapCubit>().getRoute(phoneLatLng, espLatLng);
                      // Tự động fit bản đồ để hiển thị cả 2 điểm
                      _fitBounds(phoneLatLng, espLatLng);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Chỉ đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  /// Tự động zoom/pan bản đồ sao cho cả 2 điểm đều hiển thị
  void _fitBounds(LatLng point1, LatLng point2) {
    final bounds = LatLngBounds.fromPoints([point1, point2]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.map, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Bản đồ',
              style: AppTypography.display.copyWith(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          return BlocBuilder<DeviceCubit, DeviceState>(
            builder: (context, deviceState) {
              final device = deviceState.deviceData;
              final espLatLng = device != null
                  ? LatLng(device.lat, device.lng)
                  : const LatLng(10.7769, 106.7009);

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: espLatLng,
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 19.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapState.currentLayer == MapLayer.map
                            ? 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                            : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      ),
                      // Vẽ tuyến đường (Polyline) nếu có dữ liệu route
                      if (mapState.routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: mapState.routePoints,
                              strokeWidth: 5.0,
                              color: Colors.blue.shade700,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: mapState.phoneLatLng,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.mapPhone,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          Marker(
                            point: espLatLng,
                            width: 60,
                            height: 60,
                            child: GestureDetector(
                              onTap: () {
                                if (device != null) {
                                  _showDeviceDetails(
                                      context, device, mapState.phoneLatLng);
                                }
                              },
                              child: const EspMarkerWidget(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Thanh chọn loại bản đồ
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SegmentedButton<MapLayer>(
                        segments: const [
                          ButtonSegment(value: MapLayer.map, label: Text('Bản đồ'), icon: Icon(Icons.map_outlined, size: 16)),
                          ButtonSegment(value: MapLayer.satellite, label: Text('Vệ tinh'), icon: Icon(Icons.satellite_alt, size: 16)),
                        ],
                        selected: {mapState.currentLayer},
                        onSelectionChanged: (v) =>
                            context.read<MapCubit>().toggleLayer(v.first),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColors.primary;
                            }
                            return Colors.transparent;
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return AppColors.textSecondary;
                          }),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loading indicator khi đang tải tuyến đường
                  if (mapState.isLoadingRoute)
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Đang tải tuyến đường...',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Các nút điều hướng camera + nút Xóa đường
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút Xóa đường - chỉ hiện khi có route
                        if (mapState.routePoints.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'btn_clear_route',
                              backgroundColor: Colors.red.shade400,
                              tooltip: 'Xóa đường đi',
                              onPressed: () =>
                                  context.read<MapCubit>().clearRoute(),
                              child: const Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                        FloatingActionButton.small(
                          heroTag: 'btn_esp',
                          backgroundColor: AppColors.primary,
                          tooltip: 'Đến vị trí ESP32',
                          child: const Icon(Icons.my_location, color: Colors.white),
                          onPressed: () => _mapController.move(espLatLng, 16.0),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'btn_phone',
                          backgroundColor: AppColors.mapPhone,
                          tooltip: 'Đến vị trí điện thoại',
                          child: const Icon(Icons.smartphone, color: Colors.white),
                          onPressed: () =>
                              _mapController.move(mapState.phoneLatLng, 16.0),
                        ),
                      ],
                    ),
                  ),

                  // Card thông tin tọa độ ESP32
                  if (device != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 72,
                      child: Container(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.sensors, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ESP32: ${device.lat}°N, ${device.lng}°E',
                                      style: AppTypography.data.copyWith(color: Colors.white, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white70, size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cập nhật lúc: ${DateFormatter.formatTime(device.timestamp)}',
                                    style: AppTypography.caption.copyWith(color: Colors.white70),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.gps_fixed, color: Colors.white70, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '±${device.gpsAccuracy}m',
                                    style: AppTypography.caption.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
