import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/app/routes/app_routes.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/app/theme/themeExtension.dart';
import 'package:realtime_location_tracking/features/admin/admin_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchAllUsers();
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
              'User Management',
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
                  'Manage App Users',
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
              onTap: () => context.read<AdminController>().fetchAllUsers(),
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
          if (ctrl.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  const Text('No users found'),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: ctrl.users.length,
            separatorBuilder: (_, _) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final user = ctrl.users[index];
              return _buildUserTile(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? 'No Email';
    final role = user['role'] ?? 'user';
    final bool isLiveSharing = user['is_live_sharing'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.isDarkTheme
                ? Colors.black26
                : Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: role == 'admin'
              ? Colors.red.withValues(alpha: .1)
              : Colors.blue.withValues(alpha: .1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: role == 'admin' ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            color: context.isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        childrenPadding: EdgeInsets.all(16.w),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _buildInfoRow('User ID', user['id'].toString()),
          SizedBox(height: 8.h),
          _buildInfoRow('Role', role.toString().toUpperCase()),
          SizedBox(height: 8.h),
          if (isLiveSharing)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  context.pushNamed(
                    AppRouteNames.adminLiveLocation,
                    extra: {
                      'userAuthUid': user['auth_uid'],
                      'userName': user['full_name'] ?? 'User',
                    },
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text(
                  'Go Live Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            '$label:',
            style: TextStyle(
              color: context.isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
