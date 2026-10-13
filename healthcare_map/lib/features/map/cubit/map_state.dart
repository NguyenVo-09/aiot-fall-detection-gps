import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum MapLayer { map, satellite }

class MapState extends Equatable {
  final MapLayer currentLayer;
  final LatLng phoneLatLng;
  final List<LatLng> routePoints;
  final bool isLoadingRoute;

  const MapState({
    this.currentLayer = MapLayer.map,
    this.phoneLatLng = const LatLng(10.7760, 106.7010), 
    this.routePoints = const [],
    this.isLoadingRoute = false,
  });

  MapState copyWith({
    MapLayer? currentLayer,
    LatLng? phoneLatLng,
    List<LatLng>? routePoints,
    bool? isLoadingRoute,
  }) {
    return MapState(
      currentLayer: currentLayer ?? this.currentLayer,
      phoneLatLng: phoneLatLng ?? this.phoneLatLng,
      routePoints: routePoints ?? this.routePoints,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
    );
  }

  @override
  List<Object?> get props => [currentLayer, phoneLatLng, routePoints, isLoadingRoute];
}
