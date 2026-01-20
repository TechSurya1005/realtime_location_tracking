import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/app/theme/themeExtension.dart';
import 'package:realtime_location_tracking/features/admin/admin_controller.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchAllReports();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
              'Reports & Issues',
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
                  'User Field Submissions',
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
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.read<AdminController>().fetchAllReports(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: Consumer<AdminController>(
        builder: (context, ctrl, _) {
          final query = _searchController.text.toLowerCase();

          final filteredReports = ctrl.reports.where((report) {
            final title = report['report_title']?.toString() ?? '';
            final userMap = report['users'] as Map<String, dynamic>?;
            final userName = userMap?['full_name']?.toString() ?? 'Unknown';

            final nameMatches = userName.toLowerCase().contains(query);
            final titleMatches = title.toLowerCase().contains(query);

            bool dateMatches = true;
            if (_selectedDate != null) {
              final reportDateStr = report['created_at']?.toString() ?? '';
              if (reportDateStr.isNotEmpty) {
                final reportDate = DateTime.parse(reportDateStr);
                dateMatches =
                    reportDate.year == _selectedDate!.year &&
                    reportDate.month == _selectedDate!.month &&
                    reportDate.day == _selectedDate!.day;
              }
            }

            return (nameMatches || titleMatches) && dateMatches;
          }).toList();

          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: AppTextStyle.bodyLargeStyle(context),
                            decoration: InputDecoration(
                              hintText: 'Search by Name or Issue Title',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: _selectedDate != null
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedDate != null
                                  ? Border.all(color: AppColors.primary)
                                  : null,
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: _selectedDate != null
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDate != null ||
                        _searchController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Row(
                          children: [
                            if (_selectedDate != null)
                              Text(
                                'Filtered by Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text(
                                'Clear Filters',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ctrl.loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 60.sp,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No reports found',
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
                        itemCount: filteredReports.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          return _buildReportTile(filteredReports[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportTile(Map<String, dynamic> report) {
    final userMap = report['users'] as Map<String, dynamic>?;
    final userName = userMap?['full_name']?.toString() ?? 'Unknown';
    final title = report['report_title']?.toString() ?? 'No Title';
    final summary = report['meeting_summary']?.toString() ?? 'No Summary';
    final city = report['visit_city']?.toString() ?? 'N/A';
    final area = report['visit_area']?.toString() ?? 'N/A';
    final meetingWith = report['meeting_with']?.toString() ?? 'N/A';
    final mobile = report['mobile_number']?.toString() ?? 'N/A';

    final visitDateStr = report['visit_date']?.toString() ?? '';
    final visitDate = visitDateStr.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(visitDateStr))
        : 'N/A';

    final createdAtStr = report['created_at']?.toString() ?? '';
    final createdAt = createdAtStr.isNotEmpty
        ? DateTime.parse(createdAtStr)
        : DateTime.now();

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
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: AppTextStyle.labelMediumStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              userName.toUpperCase(),
              style: AppTextStyle.labelMediumStyle(context),
            ),
            Text(
              DateFormat('MMM dd, hh:mm a').format(createdAt),
              style: TextStyle(
                fontSize: 10.sp,
                color: context.isDarkTheme
                    ? Colors.grey[500]
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
        childrenPadding: EdgeInsets.all(16.w),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _buildDetailRow(
            'Visit Date',
            visitDate,
            Icons.calendar_today_rounded,
          ),
          _buildDetailRow(
            'Location',
            '$city, $area',
            Icons.location_on_rounded,
          ),
          _buildDetailRow('Meeting With', meetingWith, Icons.person_rounded),
          _buildDetailRow('Mobile', mobile, Icons.phone_android_rounded),
          const SizedBox(height: 12),
          Text(
            'Meeting Summary:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: context.isDarkTheme ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.isDarkTheme ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.isDarkTheme ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.isDarkTheme ? Colors.white : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
