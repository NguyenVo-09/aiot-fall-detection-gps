import 'package:flutter/material.dart';
import '../widgets/fall_event_tile.dart';
import '../../../models/fall_event.dart';
import '../../../services/device_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:get_it/get_it.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<DeviceRepository>();

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
              child: const Icon(Icons.history, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Lịch sử té ngã',
              style: AppTypography.display.copyWith(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
              tooltip: 'Lọc sự kiện',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<FallEvent>>(
        stream: repo.getFallHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Đã có lỗi xảy ra khi tải dữ liệu', style: AppTypography.body),
            );
          }

          final _events = snapshot.data ?? [];

          return _events.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary header bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: const Border(bottom: BorderSide(color: AppColors.border)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF075494)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_events.length} sự kiện',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Toàn bộ lịch sử ghi nhận',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index == 0 ||
                                  DateFormatter.formatDateOnly(event.timestamp) !=
                                      DateFormatter.formatDateOnly(_events[index - 1].timestamp))
                                _buildDateHeader(event.timestamp),
                              FallEventTile(
                                event: event,
                                onMapTapped: () {},
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.formatDateOnly(timestamp),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: AppColors.border),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('An toàn!', style: AppTypography.display.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
            'Chưa có sự kiện té ngã nào\nđược ghi nhận.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
