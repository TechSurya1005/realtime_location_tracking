import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/app/theme/themeExtension.dart';
import 'package:realtime_location_tracking/features/admin/location_history_controller.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<LocationHistoryController>();
      ctrl.fetchUsersWithHistory();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final ctrl = context.read<LocationHistoryController>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != ctrl.selectedDate) {
      ctrl.setDate(picked);
    }
  }

  Widget _buildRoundAction({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ktGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location History',
              style: AppTextStyle.titleMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'User Track Records',
                  style: AppTextStyle.bodySmallStyle(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<LocationHistoryController>(
            builder: (context, ctrl, _) {
              return _buildRoundAction(
                onTap: () => _selectDate(context),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: ctrl.selectedDate != null
                      ? AppColors.accent
                      : Colors.white,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildRoundAction(
            onTap: () => context
                .read<LocationHistoryController>()
                .fetchUsersWithHistory(),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: Consumer<LocationHistoryController>(
        builder: (context, ctrl, _) {
          return Column(
            children: [
              if (ctrl.selectedDate != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'History for: ${DateFormat('dd MMM yyyy').format(ctrl.selectedDate!)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => ctrl.setDate(null),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ctrl.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ctrl.usersWithHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 60.sp,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No history found for this date',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(16.w),
                        itemCount: ctrl.usersWithHistory.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final user = ctrl.usersWithHistory[index];
                          return _buildUserExpansionTile(context, ctrl, user);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserExpansionTile(
    BuildContext context,
    LocationHistoryController ctrl,
    Map<String, dynamic> user,
  ) {
    final String uid = user['user_auth_uid'] ?? '';
    final String name = user['full_name'] ?? 'Unknown User';
    final String email = user['email'] ?? '';
    final bool isLoading = ctrl.isHistoryLoading(uid);
    final history = ctrl.userHistoryMap[uid] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: .1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.isDarkTheme ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        onExpansionChanged: (expanded) {
          if (expanded && history.isEmpty) {
            ctrl.fetchHistoryForUser(uid);
          }
        },
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No location records for this user.'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, idx) {
                final item = history[idx];
                return _buildHistoryItem(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final address = item['full_address'] ?? 'No address found';
    final lat = item['latitude']?.toStringAsFixed(6) ?? '--';
    final lng = item['longitude']?.toStringAsFixed(6) ?? '--';
    final accuracy = item['accuracy']?.toStringAsFixed(1) ?? '--';
    final createdAtStr = item['created_at']?.toString() ?? '';
    final createdAt = createdAtStr.isNotEmpty
        ? DateTime.parse(createdAtStr)
        : DateTime.now();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            address,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: context.isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              _buildInfoBadge('Acc: ${accuracy}m', Colors.blue),
              SizedBox(width: 8.w),
              Text(
                'Lat: $lat, Lng: $lng',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.isDarkTheme
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
            style: TextStyle(
              fontSize: 11.sp,
              color: context.isDarkTheme ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
