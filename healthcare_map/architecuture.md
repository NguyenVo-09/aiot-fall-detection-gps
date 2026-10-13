# Thiết Kế Giao Diện Flutter — Fall Detection App
> Phiên bản: 1.0.0 | Ngày: 2026-06-23
> Design system: pharma-clean | State management: BLoC/Cubit

---

## Mục lục

1. [Kiến trúc tổng thể](#1-kiến-trúc-tổng-thể)
2. [Cấu trúc thư mục project](#2-cấu-trúc-thư-mục-project)
3. [Màn hình Dashboard (Tab 1)](#3-màn-hình-dashboard-tab-1)
4. [Màn hình Bản đồ (Tab 2)](#4-màn-hình-bản-đồ-tab-2)
5. [Màn hình Lịch sử té ngã (Tab 3)](#5-màn-hình-lịch-sử-té-ngã-tab-3)
6. [Màn hình Cài đặt (Tab 4)](#6-màn-hình-cài-đặt-tab-4)
7. [Bottom Sheet & Dialog](#7-bottom-sheet--dialog)
8. [Frontend Implementation](#8-frontend-implementation)
9. [Backend Architecture](#9-backend-architecture)
10. [Data Flow](#10-data-flow)

---

## 1. Kiến trúc tổng thể

```
┌─────────────────────────────────────────┐
│              Flutter App                 │
│  ┌──────────┐  ┌──────────┐             │
│  │  UI Layer│  │ BLoC/    │             │
│  │ (Widgets)│◄─│ Cubit    │             │
│  └──────────┘  └────┬─────┘             │
│                     │                   │
│  ┌──────────────────▼──────────────┐    │
│  │        Repository Layer          │    │
│  │  MqttService │ FirebaseService   │    │
│  │  GeoService  │ LocalCacheService │    │
│  └──────┬───────────────┬──────────┘    │
└─────────│───────────────│───────────────┘
          │               │
    ┌─────▼──────┐  ┌─────▼──────┐
    │ MQTT Broker│  │  Firebase  │
    │ (HiveMQ)   │  │ Firestore  │
    └─────▲──────┘  └─────▲──────┘
          │               │
    ┌─────┴───────────────┴──────┐
    │       ESP32 + SIM 4G       │
    │  MPU6050 | GPS | Battery   │
    └────────────────────────────┘
```

**Nguyên tắc thiết kế giao diện:**
- **Giao diện trước, dữ liệu sau:** Toàn bộ UI xây dựng với mock data trước. Sau khi UI hoàn chỉnh mới kết nối MQTT/Firebase.
- **Offline-first:** UI luôn hiển thị được dù không có internet (từ cache)
- **Single source of truth:** State quản lý hoàn toàn bằng BLoC

---

## 2. Cấu trúc thư mục project

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, theme, router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Toàn bộ color tokens
│   │   ├── app_typography.dart     # TextStyle definitions
│   │   ├── app_spacing.dart        # Padding/margin constants
│   │   └── app_strings.dart        # Mọi chuỗi UI
│   ├── theme/
│   │   └── app_theme.dart          # ThemeData tổng hợp
│   └── utils/
│       ├── date_formatter.dart
│       └── gps_formatter.dart
│
├── features/
│   ├── dashboard/
│   │   ├── cubit/device_cubit.dart
│   │   ├── cubit/device_state.dart
│   │   ├── view/dashboard_screen.dart
│   │   └── widgets/
│   │       ├── device_status_card.dart
│   │       ├── battery_indicator.dart
│   │       ├── fall_alert_banner.dart
│   │       └── quick_info_row.dart
│   │
│   ├── map/
│   │   ├── cubit/map_cubit.dart
│   │   ├── cubit/map_state.dart
│   │   ├── view/map_screen.dart
│   │   └── widgets/
│   │       ├── map_layer_toggle.dart
│   │       ├── esp_marker.dart
│   │       ├── phone_marker.dart
│   │       ├── fall_history_layer.dart
│   │       └── map_fab_buttons.dart
│   │
│   ├── history/
│   │   ├── cubit/history_cubit.dart
│   │   ├── cubit/history_state.dart
│   │   ├── view/history_screen.dart
│   │   └── widgets/
│   │       ├── fall_event_tile.dart
│   │       └── history_empty_state.dart
│   │
│   └── settings/
│       ├── view/settings_screen.dart
│       └── widgets/settings_section.dart
│
├── services/
│   ├── mqtt_service.dart
│   ├── firebase_service.dart
│   ├── geo_service.dart
│   └── local_cache_service.dart
│
├── models/
│   ├── device_data.dart            # Model dữ liệu từ ESP32
│   └── fall_event.dart             # Model sự kiện té ngã
│
└── shared/
    └── widgets/
        ├── status_badge.dart
        ├── section_header.dart
        └── loading_shimmer.dart
```

---

## 3. Màn hình Dashboard (Tab 1)

### 3.1 Wireframe

```
┌─────────────────────────────────┐
│  ←  Fall Detection          🔔  │  ← AppBar
├─────────────────────────────────┤
│ ⚠ Phát hiện té ngã — 14:32:05  │  ← Alert Banner (chỉ hiện khi có)
├─────────────────────────────────┤
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  THIẾT BỊ                 ║  │
│  ║  ● Online   [73%] 🔋      ║  │  ← DeviceStatusCard
│  ║  ESP32_001                ║  │
│  ║  Cập nhật: 14:33:21       ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  ╔═══════════╗ ╔═══════════╗   │
│  ║ VỊ TRÍ   ║ ║ TÉ NGÃ   ║   │  ← QuickInfoRow
│  ║ ESP32     ║ ║ HÔM NAY  ║   │
│  ║ 10.7769°N ║ ║    2     ║   │
│  ║ 106.700°E ║ ║  lần     ║   │
│  ╚═══════════╝ ╚═══════════╝   │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║ 📍 BẢN ĐỒ NHANH           ║  │
│  ║                           ║  │
│  ║    [mini map 240px tall]  ║  │  ← EmbeddedMiniMap
│  ║    với marker ESP32       ║  │
│  ║                           ║  │
│  ║  [Xem bản đồ đầy đủ →]   ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║ SỰ KIỆN GẦN ĐÂY          ║  │
│  ║  ⚠ 14:32 — Phát hiện té  ║  │
│  ║  ✓ 09:15 — Thiết bị khởi ║  │  ← RecentEvents
│  ╚═══════════════════════════╝  │
│                                 │
├─────────────────────────────────┤
│  🏠 Tổng quan │ 🗺 Bản đồ │ 📋 │  ← Bottom Nav
└─────────────────────────────────┘
```

### 3.2 DeviceStatusCard

```dart
// Widget: device_status_card.dart
// Hiển thị: trạng thái online/offline, pin, thời gian cập nhật cuối

Card(
  color: Colors.white,
  child: Column(children: [
    Row(children: [
      StatusBadge(status: device.status),   // ● Online / ● Offline
      Spacer(),
      BatteryIndicator(percent: device.batteryPct),  // 🔋 73%
    ]),
    Text(device.deviceId),                   // ESP32_001
    Text('Cập nhật: ${formatTime(device.timestamp)}'),
  ]),
)
```

**Trạng thái UI:**
- `loading` → Shimmer skeleton 3 dòng
- `online` → card bình thường, border success nhẹ
- `offline` → card mờ 70% opacity, badge xám
- `fall_detected` → card border đỏ, shadow đỏ, banner xuất hiện

### 3.3 BatteryIndicator Widget

```
< 20%  → 🔴 battery_alert   + text đỏ + haptic
20-60% → 🟡 battery_3_bar  + text vàng
> 60%  → 🟢 battery_full   + text xanh

Format hiển thị: "73%" (JetBrains Mono font)
```

### 3.4 Fall Alert Banner

```dart
// Hiển thị phía trên content, dưới AppBar
// Animated slide-down khi xuất hiện

AnimatedContainer(
  height: hasFallAlert ? 56.0 : 0.0,
  color: AppColors.danger,
  child: Row(children: [
    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
    Text('Phát hiện té ngã — ${formatTime(fallTime)}',
         style: AppTypography.alert),
    Spacer(),
    TextButton('Xem', onPressed: navigateToDetail),
  ]),
)
```

---

## 4. Màn hình Bản đồ (Tab 2)

### 4.1 Wireframe

```
┌─────────────────────────────────┐
│  ←  Bản đồ                  ⋮  │  ← AppBar
├─────────────────────────────────┤
│                                 │
│  ┌─── Layer Toggle ────────┐    │
│  │ [Bản đồ] [Vệ tinh]     │    │  ← MapLayerToggle (floating chip)
│  └─────────────────────────┘    │
│                                 │
│                                 │
│         [FlutterMap]            │
│                                 │
│    📍 Thiết bị (ESP32)          │  ← Marker xanh, pulse ring
│         •                       │
│              📱 Bạn             │  ← Marker tím
│                                 │
│    ⚠ (fall history cluster)     │  ← Marker đỏ static
│                                 │
│                                 │
│                    [+]          │  ← Zoom controls
│                    [-]          │
│                                 │
│  ┌──────────────────────────┐   │
│  │  📍 ESP32: 10.7769, 106.7│   │  ← Info strip (bottom)
│  │  Chính xác: ±5m          │   │
│  └──────────────────────────┘   │
│                                 │
│  [📍 Đến ESP32] [📱 Đến tôi]   │  ← FAB buttons
│                                 │
├─────────────────────────────────┤
│  🏠        │ 🗺 ACTIVE │ 📋 │⚙ │
└─────────────────────────────────┘
```

### 4.2 FlutterMap Configuration

```dart
// map_screen.dart

FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: LatLng(10.7769, 106.7009),
    initialZoom: 15.0,
    minZoom: 3.0,
    maxZoom: 19.0,
  ),
  children: [
    // Layer 1: Tile (bản đồ thường hoặc vệ tinh)
    TileLayer(
      urlTemplate: isMapMode
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    ),

    // Layer 2: Fall history markers
    MarkerLayer(markers: fallHistoryMarkers),

    // Layer 3: Phone marker
    MarkerLayer(markers: [phoneMarker]),

    // Layer 4: ESP32 marker (top, với pulse animation)
    MarkerLayer(markers: [espMarker]),
  ],
)
```

### 4.3 Marker Design

**ESP32 Marker (marker_esp.dart):**
```dart
// Pulse animation + shield icon
Stack(children: [
  // Vòng pulse (AnimatedBuilder)
  AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) => Container(
      width: 40 + (_pulseController.value * 20),
      height: 40 + (_pulseController.value * 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(
          0.4 - (_pulseController.value * 0.4)
        ),
      ),
    ),
  ),
  // Icon chính
  Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Icon(Icons.sensors, color: Colors.white, size: 20),
  ),
])
```

**Phone Marker:** Circle tím đơn giản, border trắng

**Fall History Marker:** Warning triangle đỏ, kích thước nhỏ hơn

### 4.4 Layer Toggle

```dart
// Chip toggle: Bản đồ ↔ Vệ tinh
SegmentedButton<MapLayer>(
  segments: [
    ButtonSegment(value: MapLayer.map,       label: Text('Bản đồ')),
    ButtonSegment(value: MapLayer.satellite, label: Text('Vệ tinh')),
  ],
  selected: {currentLayer},
  onSelectionChanged: (v) => setState(() => currentLayer = v.first),
)
```

### 4.5 FAB Buttons

```dart
Column(children: [
  FloatingActionButton.small(
    heroTag: 'btn_esp',
    backgroundColor: AppColors.primary,
    child: Icon(Icons.my_location),
    onPressed: () => _mapController.move(espLatLng, 16.0),
    tooltip: 'Đến vị trí ESP32',
  ),
  SizedBox(height: 8),
  FloatingActionButton.small(
    heroTag: 'btn_phone',
    backgroundColor: AppColors.mapPhone,
    child: Icon(Icons.smartphone),
    onPressed: () => _mapController.move(phoneLatLng, 16.0),
    tooltip: 'Đến vị trí tôi',
  ),
])
```

### 4.6 Marker Tap → Bottom Sheet

Khi tap vào marker ESP32:
```
╔═══════════════════════════════╗
║ ●  ESP32_001           × ║
╠═══════════════════════════════╣
║ 📍 10.77692°N, 106.70091°E   ║
║ ⏱ Cập nhật: 14:33:21         ║
║ 🔋 73%  •  RSSI: -67 dBm     ║
║ Chính xác GPS: ±5.2m         ║
╠═══════════════════════════════╣
║ [Chỉ đường]  [Chia sẻ vị trí]║
╚═══════════════════════════════╝
```

---

## 5. Màn hình Lịch sử té ngã (Tab 3)

### 5.1 Wireframe

```
┌─────────────────────────────────┐
│  ←  Lịch sử té ngã          🔍 │
├─────────────────────────────────┤
│  Lọc: [Hôm nay ▾]  [Tất cả ▾] │  ← Filter row
├─────────────────────────────────┤
│                                 │
│  ── Hôm nay, 23/06/2026 ──     │
│                                 │
│  ╔════════════════════════════╗ │
│  ║ ⚠  Té ngã phát hiện       ║ │
│  ║    14:32:05                ║ │
│  ║    📍 10.7769, 106.7009   ║ │
│  ║    [Xem trên bản đồ →]    ║ │
│  ╚════════════════════════════╝ │
│                                 │
│  ╔════════════════════════════╗ │
│  ║ ⚠  Té ngã phát hiện       ║ │
│  ║    09:15:42                ║ │
│  ║    📍 10.7801, 106.6998   ║ │
│  ║    [Xem trên bản đồ →]    ║ │
│  ╚════════════════════════════╝ │
│                                 │
│  ── Hôm qua, 22/06/2026 ──     │
│                                 │
│  ╔════════════════════════════╗ │
│  ║ ⚠  Té ngã phát hiện       ║ │
│  ║    20:05:11                ║ │
│  ╚════════════════════════════╝ │
│                                 │
└─────────────────────────────────┘
```

### 5.2 FallEventTile Widget

```dart
// fall_event_tile.dart
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
  ),
  child: ListTile(
    leading: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.warning_amber_rounded, color: AppColors.danger),
    ),
    title: Text('Té ngã phát hiện', style: AppTypography.heading),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatDateTime(event.timestamp), style: AppTypography.caption),
        Text('${event.lat}°N, ${event.lng}°E',
             style: AppTypography.data),  // monospace
      ],
    ),
    trailing: TextButton.icon(
      icon: Icon(Icons.map_outlined, size: 16),
      label: Text('Bản đồ'),
      onPressed: () => navigateToMapWithEvent(event),
    ),
  ),
)
```

### 5.3 Empty State

```
Khi không có lịch sử:

        🛡
   Chưa có sự kiện

Không có té ngã nào được ghi nhận
trong khoảng thời gian đã chọn.
```

### 5.4 Mock Data (Phase 1 — trước khi kết nối Firebase)

```dart
// mock_data.dart
final List<FallEvent> mockFallEvents = [
  FallEvent(
    id: '001',
    timestamp: DateTime(2026, 6, 23, 14, 32, 5),
    lat: 10.77692,
    lng: 106.70091,
  ),
  FallEvent(
    id: '002',
    timestamp: DateTime(2026, 6, 23, 9, 15, 42),
    lat: 10.78012,
    lng: 106.69985,
  ),
];
```

---

## 6. Màn hình Cài đặt (Tab 4)

### 6.1 Wireframe

```
┌─────────────────────────────────┐
│  ←  Cài đặt                    │
├─────────────────────────────────┤
│                                 │
│  THIẾT BỊ                      │  ← Section header
│  ┌───────────────────────────┐  │
│  │ ID thiết bị      ESP32_001│  │
│  │ MQTT Broker   mqtt.xxx.io │  │
│  │ Kết nối lại          [→]  │  │
│  └───────────────────────────┘  │
│                                 │
│  THÔNG BÁO                     │
│  ┌───────────────────────────┐  │
│  │ Cảnh báo té ngã     [✓]  │  │
│  │ Âm thanh cảnh báo   [✓]  │  │
│  │ Rung thiết bị       [✓]  │  │
│  └───────────────────────────┘  │
│                                 │
│  BẢN ĐỒ                        │
│  ┌───────────────────────────┐  │
│  │ Chế độ mặc định  [Bản đồ]│  │
│  │ Tự ghim ESP32 khi mở [✓] │  │
│  └───────────────────────────┘  │
│                                 │
│  PIN CẢNH BÁO                  │
│  ┌───────────────────────────┐  │
│  │ Ngưỡng cảnh báo thấp  20%│  │
│  │ [━━━━●──────────────────] │  │  ← Slider
│  └───────────────────────────┘  │
│                                 │
│  THÔNG TIN                     │
│  ┌───────────────────────────┐  │
│  │ Phiên bản app        1.0.0│  │
│  │ Xóa cache bản đồ     [→]  │  │
│  │ Xóa lịch sử té ngã   [→]  │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

---

## 7. Bottom Sheet & Dialog

### 7.1 Fall Detail Bottom Sheet

Hiển thị khi tap vào alert banner hoặc fall event tile:

```
╔═══════════════════════════════════╗
║ ⚠  TÉ NGÃ PHÁT HIỆN              ║
╠═══════════════════════════════════╣
║  Thời gian:   14:32:05, 23/06    ║
║  Vị trí:      10.77692°N          ║
║               106.70091°E         ║
║  Chính xác:   ±5.2m               ║
║  Pin lúc đó:  73%                  ║
╠═══════════════════════════════════╣
║  [mini map với fall marker]       ║
╠═══════════════════════════════════╣
║  [Xem trên bản đồ đầy đủ]        ║
║  [Chia sẻ vị trí]    [Đóng]      ║
╚═══════════════════════════════════╝
```

### 7.2 Xác nhận xóa lịch sử

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Xóa lịch sử?'),
    content: Text('Toàn bộ dữ liệu té ngã sẽ bị xóa vĩnh viễn.'),
    actions: [
      TextButton('Hủy', onPressed: Navigator.pop),
      TextButton('Xóa', style: danger, onPressed: confirmDelete),
    ],
  ),
)
```

---

## 8. Frontend Implementation

### 8.1 Giai đoạn 1 — UI với Mock Data

Mọi screen xây dựng với `MockRepository` trả về dữ liệu tĩnh. Cubit nhận mock data như thật.

```dart
// di/injection.dart (giai đoạn 1)
getIt.registerLazySingleton<DeviceRepository>(
  () => MockDeviceRepository(),  // Trả mock data
);

// Giai đoạn 2: thay bằng
getIt.registerLazySingleton<DeviceRepository>(
  () => MqttDeviceRepository(mqttService: getIt()),
);
```

### 8.2 AppTheme (app_theme.dart)

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.display,
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
```

### 8.3 AppColors (app_colors.dart)

```dart
class AppColors {
  AppColors._();
  static const primary       = Color(0xFF0A6EBD);
  static const surface       = Color(0xFFF5F7FA);
  static const surfaceCard   = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE2E6EA);
  static const textPrimary   = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6B7280);
  static const danger        = Color(0xFFDC2626);
  static const warning       = Color(0xFFF59E0B);
  static const success       = Color(0xFF16A34A);
  static const mapEsp        = Color(0xFF0A6EBD);
  static const mapPhone      = Color(0xFF7C3AED);
}
```

### 8.4 Models

```dart
// models/device_data.dart
class DeviceData {
  final String deviceId;
  final int timestamp;
  final bool fallDetected;
  final double lat;
  final double lng;
  final double gpsAccuracy;
  final int batteryPct;
  final int rssi;

  DeviceStatus get status {
    final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - timestamp;
    if (age > 60) return DeviceStatus.offline;
    if (fallDetected) return DeviceStatus.fall;
    return DeviceStatus.online;
  }
}

// models/fall_event.dart
class FallEvent {
  final String id;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final int batteryAtEvent;
}
```

### 8.5 DeviceCubit

```dart
class DeviceCubit extends Cubit<DeviceState> {
  final DeviceRepository _repo;

  DeviceCubit(this._repo) : super(DeviceState.loading()) {
    _repo.deviceStream.listen((data) {
      emit(DeviceState.loaded(data));
      if (data.fallDetected) _triggerFallAlert(data);
    });
  }

  void _triggerFallAlert(DeviceData data) {
    HapticFeedback.vibrate();
    // Vibration pattern: 500-200-500
    emit(state.copyWith(activeFallAlert: true));
  }

  void dismissAlert() => emit(state.copyWith(activeFallAlert: false));
}
```

---

## 9. Backend Architecture

### 9.1 MQTT Topics

```
Topic structure: fall_detection/{device_id}/{data_type}

fall_detection/ESP32_001/telemetry   → JSON payload (status, GPS, battery)
fall_detection/ESP32_001/fall        → {"detected": true, "timestamp": ...}
fall_detection/ESP32_001/ack         → App gửi xác nhận nhận cảnh báo
```

**Payload telemetry (ESP32 → Broker → App):**
```json
{
  "device_id": "ESP32_001",
  "timestamp": 1719100000,
  "fall_detected": false,
  "lat": 10.77692,
  "lng": 106.70091,
  "gps_accuracy": 5.2,
  "battery_pct": 73,
  "rssi": -67
}
```

### 9.2 Firebase Firestore Schema

```
Collection: fall_events
Document ID: auto-generated
Fields:
  - device_id: string
  - timestamp: Timestamp
  - lat: number
  - lng: number
  - gps_accuracy: number
  - battery_at_event: number
  - acknowledged: boolean
  - acknowledged_at: Timestamp | null

Collection: device_config
Document ID: {device_id}
Fields:
  - device_name: string
  - owner_uid: string
  - alert_threshold_battery: number  (default: 20)
  - created_at: Timestamp
```

### 9.3 Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /fall_events/{eventId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.owner_uid;
    }

    match /device_config/{deviceId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.owner_uid;
    }
  }
}
```

### 9.4 MqttService (Singleton)

```dart
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  late MqttServerClient _client;
  final _dataController = StreamController<DeviceData>.broadcast();
  Stream<DeviceData> get dataStream => _dataController.stream;

  Future<void> connect({
    required String broker,
    required int port,           // 8883 (TLS)
    required String username,
    required String password,
    required String deviceId,
  }) async {
    _client = MqttServerClient.withPort(broker, 'flutter_client', port);
    _client.secure = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    final connMsg = MqttConnectMessage()
      .authenticateAs(username, password)
      .withWillTopic('fall_detection/$deviceId/status')
      .withWillMessage('{"online": false}')
      .startClean();

    _client.connectionMessage = connMsg;
    await _client.connect();
    _subscribe('fall_detection/$deviceId/telemetry');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    final payload = messages[0].payload as MqttPublishMessage;
    final jsonStr = MqttPublishPayload.bytesToStringAsString(
      payload.payload.message
    );
    final data = DeviceData.fromJson(jsonDecode(jsonStr));
    _dataController.add(data);
  }
}
```

### 9.5 FirebaseService

```dart
class FirebaseService {
  final _db = FirebaseFirestore.instance;

  // Lắng nghe fall events realtime
  Stream<List<FallEvent>> fallEventsStream(String deviceId) {
    return _db
      .collection('fall_events')
      .where('device_id', isEqualTo: deviceId)
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => FallEvent.fromFirestore(doc))
          .toList());
  }

  // Ghi fall event (trigger từ MQTT hoặc ESP32 trực tiếp)
  Future<void> saveFallEvent(FallEvent event) async {
    await _db.collection('fall_events').add(event.toMap());
  }
}
```

---

## 10. Data Flow

### 10.1 Flow chính: ESP32 → App

```
ESP32
  │  Phát hiện té ngã (IMU threshold)
  │  Ghi GPS coordinates
  │  Tính % pin
  ▼
SIM 4G Module
  │  Gửi MQTT publish: fall_detection/ESP32_001/telemetry
  │  QoS: 1 (at least once)
  ▼
MQTT Broker (HiveMQ Cloud)
  │  Forward đến subscribers
  ▼
Flutter App (MqttService)
  │  onMessage callback
  │  Parse JSON → DeviceData model
  ▼
DeviceCubit
  │  emit(DeviceState.loaded(data))
  │  Nếu fallDetected: emit alert + haptic
  ▼
UI (Dashboard + Alert Banner)
  │  Rebuild với data mới
  │  Show fall alert banner
  ▼
Firebase (parallel)
  │  Ghi FallEvent vào Firestore
  ▼
FCM Push Notification
  │  Nếu app ở background → push notification
```

### 10.2 Flow lịch sử té ngã

```
HistoryScreen mở
  ▼
HistoryCubit.load()
  ▼
FirebaseService.fallEventsStream(deviceId)
  ▼ (realtime snapshot)
List<FallEvent>
  ▼
HistoryCubit.emit(HistoryState.loaded(events))
  ▼
ListView với FallEventTile
```

### 10.3 Flow xem vị trí trên bản đồ

```
MapScreen mở
  ▼
MapCubit.init()
  │  ├─ GeoService.getPhoneLocation() → LatLng phone
  │  └─ subscribe DeviceCubit.stream → LatLng esp
  ▼
MapState.loaded(espLatLng, phoneLatLng, fallEvents)
  ▼
FlutterMap rebuild markers
  │  ├─ EspMarker (pulse animation)
  │  ├─ PhoneMarker
  │  └─ FallHistoryMarkers
  ▼
User tap FAB "Đến ESP32"
  ▼
_mapController.animatedMove(espLatLng, 16.0)
```

---

## Appendix A — Giai đoạn phát triển

| Giai đoạn | Nội dung | Ước tính |
|---|---|---|
| **Phase 1** | Toàn bộ UI với mock data, navigation, animations | 1–2 tuần |
| **Phase 2** | Kết nối MQTT, nhận data thật từ ESP32 simulator | 1 tuần |
| **Phase 3** | Kết nối Firebase, lịch sử thật, push notification | 1 tuần |
| **Phase 4** | Test end-to-end với phần cứng thật, fix edge cases | 1 tuần |

---

## Appendix B — Checklist UI Phase 1

- [ ] AppTheme, AppColors, AppTypography hoàn chỉnh
- [ ] Bottom navigation với 4 tab
- [ ] Dashboard screen với mock DeviceData
- [ ] BatteryIndicator với 3 trạng thái màu
- [ ] FallAlertBanner animate slide-down
- [ ] MapScreen với FlutterMap + mock markers
- [ ] EspMarker pulse animation
- [ ] MapLayerToggle (Bản đồ / Vệ tinh)
- [ ] FAB "Đến ESP32" và "Đến tôi"
- [ ] HistoryScreen với mock fall events
- [ ] FallEventTile với tap → bottom sheet
- [ ] SettingsScreen với toggles và slider
- [ ] Empty state cho HistoryScreen
- [ ] Loading shimmer cho tất cả data card
- [ ] Responsive layout (test trên 360px và 412px width)
