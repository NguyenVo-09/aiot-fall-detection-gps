# Ràng Buộc Thiết Kế — Fall Detection IoT System
> Design System: **pharma-clean** (npx designdotmd add pharma-clean)
> Ngày: 2026-06-23 | Phiên bản: 1.0.0

---

## 1. Tổng quan hệ thống

Thiết bị IoT phát hiện té ngã đeo người, tích hợp GPS + SIM 4G, giao tiếp với app Flutter. Hệ thống bao gồm:

- **Phần cứng (ESP32):** MPU6050/IMU, GPS module, SIM 4G (SIM7600/A7670), pin LiPo, buzzer
- **Backend:** MQTT Broker (HiveMQ / Mosquitto) + Firebase Firestore / REST API
- **Frontend:** Flutter app (flutter_map, geolocator, MQTT client)

---

## 2. Design Tokens — pharma-clean

### 2.1 Bảng màu (Color Palette)

| Token | Hex | Vai trò |
|---|---|---|
| `--color-primary` | `#0A6EBD` | CTA chính, icon active, accent map |
| `--color-surface` | `#F5F7FA` | Background toàn app |
| `--color-surface-card` | `#FFFFFF` | Card nội dung |
| `--color-border` | `#E2E6EA` | Divider, border card |
| `--color-text-primary` | `#1A1D23` | Tiêu đề, nội dung chính |
| `--color-text-secondary` | `#6B7280` | Mô tả phụ, timestamp |
| `--color-danger` | `#DC2626` | Cảnh báo té ngã, pin thấp |
| `--color-warning` | `#F59E0B` | Pin trung bình (20–50%) |
| `--color-success` | `#16A34A` | Thiết bị online, pin đủ |
| `--color-map-esp` | `#0A6EBD` | Marker vị trí ESP32 |
| `--color-map-phone` | `#7C3AED` | Marker vị trí điện thoại |

**Nguyên tắc màu:**
- Không dùng quá 3 màu trên 1 màn hình
- `--color-danger` chỉ dành riêng cho trạng thái khẩn cấp (té ngã detected, pin < 20%)
- Background map luôn dùng tile provider sáng để tương phản với marker

### 2.2 Typography

| Token | Font | Weight | Size | Dùng cho |
|---|---|---|---|---|
| `--font-display` | Inter | 700 | 22px | Tiêu đề màn hình |
| `--font-heading` | Inter | 600 | 18px | Card title, section header |
| `--font-body` | Inter | 400 | 14px | Nội dung chính |
| `--font-caption` | Inter | 400 | 12px | Timestamp, label phụ |
| `--font-data` | JetBrains Mono | 500 | 13px | GPS coordinates, % pin, giá trị sensor |
| `--font-alert` | Inter | 700 | 16px | Thông báo khẩn cấp |

**Nguyên tắc typography:**
- Tất cả text dạng dữ liệu (tọa độ GPS, phần trăm pin) dùng monospace font để dễ đọc
- Không dùng font size < 12px
- Line height tối thiểu 1.5 cho body text

### 2.3 Spacing & Layout

```
Base unit: 4px
--spacing-xs:   4px
--spacing-sm:   8px
--spacing-md:  16px
--spacing-lg:  24px
--spacing-xl:  32px
--spacing-2xl: 48px
```

- **Card padding:** 16px
- **Screen padding (horizontal):** 16px
- **Bottom navigation height:** 64px (+ safe area)
- **AppBar height:** 56px
- **Map height (embedded):** 240px minimum, expandable to fullscreen

### 2.4 Border & Shadow

```dart
// Card mặc định
borderRadius: 12px
border: 1px solid var(--color-border)
boxShadow: 0 1px 4px rgba(0,0,0,0.06)

// Card cảnh báo (fall detected)
borderRadius: 12px
border: 2px solid var(--color-danger)
boxShadow: 0 4px 16px rgba(220,38,38,0.15)

// Bottom sheet
borderRadius: 20px 20px 0 0
```

### 2.5 Iconography

- Bộ icon: **Material Symbols** (outlined, weight 300)
- Kích thước icon tiêu chuẩn: 24px
- Icon trong bottom nav: 24px
- Icon trong alert banner: 28px
- Icon GPS marker ESP32: custom SVG shield (16×20px)
- Icon GPS marker Phone: custom SVG circle (14×14px)

---

## 3. Ràng buộc Component

### 3.1 Status Badge

```
Trạng thái thiết bị:
● Online   → background: #DCFCE7, text: #16A34A
● Offline  → background: #F3F4F6, text: #6B7280
● Fall!    → background: #FEE2E2, text: #DC2626, animated pulse
```

**Quy tắc:**
- Badge "Fall Detected" phải animated (pulse/blink mỗi 1s)
- Badge không được nhỏ hơn 28px chiều cao
- Không được dùng badge màu đỏ cho bất kỳ trạng thái nào khác ngoài té ngã / pin cực thấp

### 3.2 Pin Indicator

```
> 60%:   màu success (#16A34A), icon battery_full
20–60%:  màu warning (#F59E0B), icon battery_3_bar
< 20%:   màu danger  (#DC2626), icon battery_alert + haptic
```

**Hiển thị:** `[icon] 73%` — luôn dùng monospace cho con số

### 3.3 Map Markers

| Marker | Màu | Shape | Label |
|---|---|---|---|
| ESP32 device | `#0A6EBD` | Shield + pulse ring | "Thiết bị" |
| Điện thoại | `#7C3AED` | Circle | "Bạn" |
| Fall event (history) | `#DC2626` | Warning triangle | thời gian |

**Quy tắc:**
- Marker ESP32 phải có pulse animation khi đang online
- Marker fall history không được animation, chỉ static
- Khi zoom < 12, gộp các fall event marker bằng cluster
- Tap vào marker → hiện bottom sheet thông tin (không navigate away khỏi map)

### 3.4 Alert Banner (Fall Detected)

```
Vị trí: Fixed top (dưới AppBar)
Chiều cao: 56px
Background: #DC2626
Text màu: #FFFFFF
Icon: warning_amber_rounded (28px)
Nội dung: "⚠ Phát hiện té ngã — [HH:MM:SS]"
Action: Tap để xem chi tiết
```

**Quy tắc:**
- Banner xuất hiện với animation slide-down (200ms ease-out)
- Không tự dismiss — user phải xác nhận
- Kèm vibration pattern: 500ms–200ms–500ms
- Âm thanh: system alert sound (nếu app ở foreground)

---

## 4. Ràng buộc Navigation

### 4.1 Bottom Navigation Bar

```
Tab 1: home_rounded        → Tổng quan (Dashboard)
Tab 2: map_rounded         → Bản đồ
Tab 3: history_rounded     → Lịch sử té ngã
Tab 4: settings_rounded    → Cài đặt
```

**Quy tắc:**
- Active tab: màu `--color-primary`
- Inactive tab: màu `--color-text-secondary`
- Label: hiển thị luôn (không ẩn khi inactive)
- Badge count trên tab Lịch sử nếu có event chưa đọc

### 4.2 Điều hướng Map

- Nút "Đến ESP32": fly-to animation (800ms)
- Nút "Đến vị trí tôi": fly-to animation (600ms)
- Zoom mặc định khi mở map: 15
- Zoom tối thiểu cho xem vệ tinh: 16

---

## 5. Ràng buộc Dữ liệu & State

### 5.1 Độ trễ hiển thị tối đa

| Dữ liệu | Latency tối đa | Protocol |
|---|---|---|
| Trạng thái té ngã | < 3 giây | MQTT QoS 1 |
| Vị trí GPS ESP32 | < 10 giây | MQTT / HTTP poll |
| % Pin ESP32 | < 30 giây | MQTT |
| Lịch sử té ngã | Real-time | Firebase snapshot |

### 5.2 Offline Behavior

- Khi mất kết nối: hiển thị banner "Mất kết nối — dữ liệu có thể không chính xác"
- Cache vị trí GPS cuối cùng vào SharedPreferences
- Lịch sử té ngã lưu offline-first (Hive / SQLite)
- Map tiles cache tối thiểu 50MB

### 5.3 Payload ESP32 → App

```json
{
  "device_id": "ESP32_001",
  "timestamp": 1719100000,
  "fall_detected": false,
  "lat": 10.7769,
  "lng": 106.7009,
  "gps_accuracy": 5.2,
  "battery_pct": 73,
  "rssi": -67
}
```

---

## 6. Ràng buộc Accessibility & UX

- Minimum tap target: **48×48px** cho mọi interactive element
- Contrast ratio text/background: tối thiểu **4.5:1** (WCAG AA)
- Alert quan trọng (fall detected) phải có cả visual + haptic + âm thanh
- Màn hình lịch sử té ngã phải hỗ trợ đọc khi không có internet (offline cache)
- Font scale: hỗ trợ đến 1.3× (người cao tuổi sử dụng)
- Dark mode: **không bắt buộc** trong v1 — pharma-clean dùng light mode

---

## 7. Ràng buộc Kỹ thuật Flutter

### 7.1 Dependencies bắt buộc

```yaml
dependencies:
  flutter_map: ^7.x          # Bản đồ OpenStreetMap
  latlong2: ^0.9.x           # Kiểu LatLng
  geolocator: ^12.x          # Vị trí điện thoại
  mqtt_client: ^10.x         # Kết nối MQTT broker
  cloud_firestore: ^5.x      # Lịch sử té ngã (Firebase)
  hive_flutter: ^1.x         # Cache offline
  firebase_messaging: ^15.x  # Push notification
  permission_handler: ^11.x  # Xin quyền GPS
  battery_plus: ^6.x         # Pin điện thoại (tham khảo)
  intl: ^0.19.x              # Format thời gian tiếng Việt
```

### 7.2 Kiến trúc State Management

- Pattern: **BLoC / Cubit**
- 1 Cubit cho mỗi feature: `DeviceCubit`, `MapCubit`, `FallHistoryCubit`, `SettingsCubit`
- MQTT service là singleton, inject qua DI (get_it)

### 7.3 Quy tắc Code

- Tên file: `snake_case.dart`
- Widget: `PascalCase`
- Không widget > 200 dòng — tách thành sub-widget
- Mọi màu phải lấy từ `AppColors` constant class (không hardcode)
- Mọi string hiển thị phải qua `AppStrings` (chuẩn bị cho đa ngôn ngữ)

---

## 8. Ràng buộc Bảo mật

- MQTT: dùng TLS (port 8883), xác thực username/password
- Firebase: rules cho phép read/write chỉ với authenticated user
- Device ID của ESP32 phải được mã hoá khi lưu trên app
- GPS coordinates không được log ra console ở production build
- Không lưu password MQTT trong plaintext — dùng Flutter Secure Storage

---

## 9. Checklist Trước Khi Release

- [ ] Thử nghiệm alert khi app ở background (FCM push notification)
- [ ] Kiểm tra map hoạt động với vệ tinh tile provider (Esri / Google Hybrid)
- [ ] Test offline: tắt internet, kiểm tra cache
- [ ] Test pin indicator với mock data ở 3 ngưỡng (>60, 20–60, <20)
- [ ] Kiểm tra marker animation không lag trên thiết bị tầm trung
- [ ] Verify font scale 1.3× không vỡ layout
- [ ] Test flow: ESP32 gửi fall_detected=true → app nhận → banner → notification

---

*Tài liệu này là nguồn tham chiếu duy nhất (single source of truth) cho toàn bộ quyết định thiết kế. Mọi ngoại lệ phải được ghi chú và lý giải.*
