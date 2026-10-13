import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import 'package:get_it/get_it.dart';
import '../../../services/device_repository.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/fall_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _fallAlertEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoPinEsp = true;
  double _batteryThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    final repo = GetIt.I<DeviceRepository>();
    _fallAlertEnabled = repo.isFallAlertEnabled;
    _batteryThreshold = repo.batteryThreshold;
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
              child: const Icon(Icons.settings, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Cài đặt',
              style: AppTypography.display.copyWith(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Device section
          _buildSectionHeader('THIẾT BỊ', Icons.devices),
          _buildCard([
            _buildInfoTile(
              icon: Icons.memory,
              iconColor: AppColors.primary,
              title: 'ID thiết bị',
              trailing: 'ESP32_001',
            ),
            const _CardDivider(),
            _buildInfoTile(
              icon: Icons.cloud,
              iconColor: AppColors.mapPhone,
              title: 'Cơ sở dữ liệu',
              trailing: 'Cloud Firestore',
            ),
          ]),
          const SizedBox(height: 24),

          // Notification section
          _buildSectionHeader('THÔNG BÁO', Icons.notifications),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.danger,
              title: 'Cảnh báo té ngã',
              subtitle: 'Thông báo khi phát hiện té ngã',
              value: _fallAlertEnabled,
              onChanged: (val) {
                setState(() => _fallAlertEnabled = val);
                GetIt.I<DeviceRepository>().setFallAlertEnabled(val);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Map section
          _buildSectionHeader('BẢN ĐỒ', Icons.map),
          _buildCard([
            _buildActionTile(
              icon: Icons.layers,
              iconColor: AppColors.primary,
              title: 'Chế độ mặc định',
              trailingLabel: 'Bản đồ',
              onTap: () {},
            ),
            const _CardDivider(),
            _buildSwitchTile(
              icon: Icons.location_searching,
              iconColor: AppColors.mapEsp,
              title: 'Tự ghim ESP32 khi mở',
              subtitle: 'Tự động di chuyển đến vị trí thiết bị',
              value: _autoPinEsp,
              onChanged: (val) => setState(() => _autoPinEsp = val),
            ),
          ]),
          const SizedBox(height: 24),

          // Battery section
          _buildSectionHeader('PIN CẢNH BÁO', Icons.battery_alert),
          _buildCard([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.battery_alert, color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ngưỡng cảnh báo thấp', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              'Cảnh báo khi pin xuống dưới ngưỡng này',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_batteryThreshold.toInt()}%',
                          style: AppTypography.data.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.danger,
                      thumbColor: AppColors.danger,
                      overlayColor: AppColors.danger.withOpacity(0.15),
                      inactiveTrackColor: AppColors.danger.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _batteryThreshold,
                      min: 10,
                      max: 50,
                      divisions: 8,
                      onChanged: (val) {
                        setState(() => _batteryThreshold = val);
                        GetIt.I<DeviceRepository>().setBatteryThreshold(val);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10%', style: AppTypography.caption),
                      Text('50%', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Info section
          _buildSectionHeader('XÓA LỊCH SỬ', Icons.info_outline),
          _buildCard([
            _buildActionTile(
              icon: Icons.delete_forever,
              iconColor: AppColors.danger,
              title: 'Xóa lịch sử té ngã',
              titleColor: AppColors.danger,
              onTap: () => _showDeleteDialog(context),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(
        trailing,
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? trailingLabel,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailingLabel != null
          ? Text(trailingLabel, style: AppTypography.body.copyWith(color: AppColors.textSecondary))
          : Icon(Icons.chevron_right, color: titleColor ?? AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DeleteHistorySheet(),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 60),
      child: Divider(height: 1, thickness: 1),
    );
  }
}

/// Bottom sheet cho phép chọn và xóa từng sự kiện té ngã
class _DeleteHistorySheet extends StatefulWidget {
  @override
  State<_DeleteHistorySheet> createState() => _DeleteHistorySheetState();
}

class _DeleteHistorySheetState extends State<_DeleteHistorySheet> {
  List<FallEvent> _events = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final repo = GetIt.I<DeviceRepository>();
    final events = await repo.getFallHistory();
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isDeleting = true);

    final repo = GetIt.I<DeviceRepository>();
    for (final id in _selectedIds) {
      await repo.deleteFallEvent(id);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${_selectedIds.length} sự kiện té ngã'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.danger.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep, color: AppColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xóa lịch sử té ngã',
                          style: AppTypography.heading.copyWith(color: AppColors.textPrimary)),
                      Text('Chọn các sự kiện muốn xóa vĩnh viễn',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Danh sách sự kiện
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('Không có lịch sử té ngã', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                        itemBuilder: (ctx, i) {
                          final event = _events[i];
                          final isSelected = _selectedIds.contains(event.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(event.id);
                                } else {
                                  _selectedIds.remove(event.id);
                                }
                              });
                            },
                            activeColor: AppColors.danger,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              DateFormatter.formatDateTime(event.timestamp),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              '🔋 ${event.batteryAtEvent}%  •  📍 ${event.lat.toStringAsFixed(4)}°N, ${event.lng.toStringAsFixed(4)}°E',
                              style: AppTypography.caption,
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                            ),
                          );
                        },
                      ),
          ),

          // Nút Chọn tất cả & Xóa
          if (!_isLoading && _events.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedIds.length == _events.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.addAll(_events.map((e) => e.id));
                        }
                      });
                    },
                    icon: Icon(
                      _selectedIds.length == _events.length
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(_selectedIds.length == _events.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed: _selectedIds.isEmpty || _isDeleting ? null : () async {
                        // Xác nhận xóa
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Xác nhận xóa'),
                            content: Text('Bạn có chắc muốn xóa ${_selectedIds.length} sự kiện đã chọn?\nHành động này không thể hoàn tác.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) await _deleteSelected();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.delete_forever, size: 18),
                      label: Text(_selectedIds.isEmpty ? 'Xóa' : 'Xóa (${_selectedIds.length})'),
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
