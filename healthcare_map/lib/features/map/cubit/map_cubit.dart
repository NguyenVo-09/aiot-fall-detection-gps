import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'map_state.dart';
import '../../../services/device_repository.dart';

class MapCubit extends Cubit<MapState> {
  final DeviceRepository _deviceRepo;

  StreamSubscription? _deviceSub;
  Timer? _routeDebounceTimer;

  // Ngưỡng di chuyển tối thiểu để cập nhật route (đơn vị: độ, ~11m)
  static const double _minMoveDeltaDeg = 0.0001;

  LatLng? _lastEspLatLng;

  MapCubit(this._deviceRepo) : super(const MapState()) {
    _listenToDevice();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    emit(state.copyWith(phoneLatLng: LatLng(position.latitude, position.longitude)));

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((Position position) {
      emit(state.copyWith(phoneLatLng: LatLng(position.latitude, position.longitude)));
    });
  }

  void _listenToDevice() {
    _deviceSub = _deviceRepo.deviceStream.listen((data) {
      final newEspLatLng = LatLng(data.lat, data.lng);

      // Chỉ xử lý nếu ESP đã thực sự di chuyển một khoảng đáng kể
      final hasMoved = _lastEspLatLng == null ||
          (newEspLatLng.latitude - _lastEspLatLng!.latitude).abs() >
              _minMoveDeltaDeg ||
          (newEspLatLng.longitude - _lastEspLatLng!.longitude).abs() >
              _minMoveDeltaDeg;

      if (!hasMoved) return;
      _lastEspLatLng = newEspLatLng;

      // Nếu đang có route hiện tại → tự động cập nhật
      if (state.routePoints.isNotEmpty) {
        // Debounce: chỉ gọi API sau 3 giây kể từ lần cập nhật vị trí cuối
        _routeDebounceTimer?.cancel();
        _routeDebounceTimer = Timer(const Duration(seconds: 3), () {
          getRoute(state.phoneLatLng, newEspLatLng);
        });
      }
    });
  }

  void toggleLayer(MapLayer layer) {
    emit(state.copyWith(currentLayer: layer));
  }

  Future<void> getRoute(LatLng start, LatLng end) async {
    emit(state.copyWith(isLoadingRoute: true, routePoints: []));

    try {
      // OSRM public API - hoàn toàn miễn phí, không cần API Key
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?geometries=geojson&overview=full',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          emit(state.copyWith(isLoadingRoute: false));
          return;
        }
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List;

        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        emit(state.copyWith(routePoints: points, isLoadingRoute: false));
      } else {
        emit(state.copyWith(isLoadingRoute: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoadingRoute: false));
    }
  }

  void clearRoute() {
    _routeDebounceTimer?.cancel();
    emit(state.copyWith(routePoints: []));
  }

  @override
  Future<void> close() {
    _deviceSub?.cancel();
    _routeDebounceTimer?.cancel();
    return super.close();
  }
}
