import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/app/theme/themeExtension.dart';
import 'package:realtime_location_tracking/features/home/home_controller.dart';

class SubmittedReportsScreen extends StatefulWidget {
  const SubmittedReportsScreen({super.key});

  @override
  State<SubmittedReportsScreen> createState() => _SubmittedReportsScreenState();
}

class _SubmittedReportsScreenState extends State<SubmittedReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().fetchUserReports();
    });
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
              'Submitted Reports',
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
                  'Your Activity History',
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
              onTap: () => context.read<HomeController>().fetchUserReports(),
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
      body: SafeArea(
        child: Consumer<HomeController>(
          builder: (context, ctrl, _) {
            if (ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final reports = ctrl.userReports;

            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment_late_outlined,
                        size: 80,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No reports submitted yet',
                      style: AppTextStyle.titleMediumStyle(
                        context,
                      ).copyWith(color: AppColors.hintColor),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];

                final title = r['report_title']?.toString() ?? 'No Title';
                final description =
                    r['meeting_summary']?.toString() ?? 'No Description';
                final visitCity = r['visit_city']?.toString() ?? '';
                final visitArea = r['visit_area']?.toString() ?? '';
                final meetingWith = r['meeting_with']?.toString() ?? '';
                final mobileNumber = r['mobile_number']?.toString() ?? '';
                final visitDateStr = r['visit_date']?.toString() ?? '';

                final createdAtStr = r['created_at']?.toString() ?? '';
                final createdAt = createdAtStr.isNotEmpty
                    ? DateTime.parse(createdAtStr)
                    : DateTime.now();
                final visitDateAt = visitDateStr.isNotEmpty
                    ? DateTime.parse(visitDateStr)
                    : DateTime.now();

                final rawImages = r['images'];
                final List<String> images = rawImages != null
                    ? List<String>.from(rawImages)
                    : [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        title,
                        style: AppTextStyle.titleMediumStyle(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(createdAt),
                          style: AppTextStyle.bodySmallStyle(
                            context,
                          ).copyWith(color: AppColors.subTitle),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // New Fields Display
                        if (visitCity.isNotEmpty || visitArea.isNotEmpty)
                          _buildDetailRow(
                            context,
                            Icons.location_on_rounded,
                            'Location',
                            '$visitCity${visitCity.isNotEmpty && visitArea.isNotEmpty ? ', ' : ''}$visitArea',
                          ),

                        if (meetingWith.isNotEmpty)
                          _buildDetailRow(
                            context,
                            Icons.person_rounded,
                            'Meeting With',
                            meetingWith,
                          ),

                        if (mobileNumber.isNotEmpty)
                          _buildDetailRow(
                            context,
                            Icons.phone_android_rounded,
                            'Mobile',
                            mobileNumber,
                          ),
                        if (visitDateStr.isNotEmpty)
                          _buildDetailRow(
                            context,
                            Icons.calendar_month,
                            'Visit Date',
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(visitDateAt),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Summary',
                          style: AppTextStyle.bodySmallStyle(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyle.bodyMediumStyle(context).copyWith(
                            height: 1.5,
                            color: AppColors.text.withValues(alpha: 0.8),
                          ),
                        ),

                        if (images.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Attachments (${images.length})',
                            style: AppTextStyle.bodySmallStyle(context)
                                .copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                return GestureDetector(
                                  onTap: () {
                                    // Could add full screen image viewer here
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: CachedNetworkImage(
                                      imageUrl: images[i],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 120,
                                        height: 120,
                                        color: AppColors.scaffoldBackground,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            width: 120,
                                            height: 120,
                                            color: AppColors.scaffoldBackground,
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: AppColors.hintColor,
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyle.bodyMediumStyle(
                  context,
                ).copyWith(color: AppColors.text),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
