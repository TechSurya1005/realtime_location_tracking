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

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh stats when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchStats();
    });
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
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pre-calculate styles here where context is valid for watching providers
    final popupTextStyle = AppTextStyle.labelMediumStyle(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.3),
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
              'Admin Dashboard',
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
                  'Overview & Management',
                  style: AppTextStyle.bodySmallStyle(context).copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildRoundAction(
            onTap: () => context.read<AdminController>().fetchStats(),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.password, color: Colors.white, size: 24),
            ),
            onSelected: (value) {
              if (value == 'change-password') {
                _showChangePasswordDialog(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'change-password',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.password,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Change Password', style: popupTextStyle),
                    ],
                  ),
                ),
              ];
            },
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
      body: Consumer<AdminController>(
        builder: (context, ctrl, _) {
          return RefreshIndicator(
            onRefresh: () async => await ctrl.fetchStats(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: REdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: context.isDarkTheme
                                ? Colors.white
                                : Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildStatsGrid(ctrl),
                        SizedBox(height: 24.h),
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: context.isDarkTheme
                                ? Colors.white
                                : Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'Add User',
                                icon: Icons.person_add_rounded,
                                color: Colors.indigo,
                                onTap: () {
                                  // Dialog to Add User
                                  _showAddUserDialog(context);
                                },
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'View Users',
                                icon: Icons.groups_rounded,
                                color: Colors.blue,
                                onTap: () {
                                  // Navigate to User List
                                  context.pushNamed(AppRouteNames.adminUsers);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildActionCard(
                          context,
                          title: 'Reports & Issues',
                          subtitle: 'Check submitted field reports',
                          icon: Icons.assignment_rounded,
                          color: Colors.orange,
                          onTap: () {
                            // Navigate to Reports
                            context.pushNamed(AppRouteNames.adminReports);
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildActionCard(
                          context,
                          title: 'Location History',
                          subtitle: 'Track user movements',
                          icon: Icons.map_rounded,
                          color: Colors.teal,
                          onTap: () {
                            context.pushNamed(AppRouteNames.locationHistory);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(AdminController ctrl) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            ctrl.stats.totalUsers.toString(),
            Icons.people,
            Colors.blue,
            loading: ctrl.loading,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            'Reports',
            ctrl.stats.totalReports.toString(),
            Icons.description,
            Colors.orange,
            loading: ctrl.loading,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter old password'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter new password';
                  if (value.length < 6) return 'Min 6 chars required';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Call API to change password
                final oldPass = oldPassController.text;
                final newPass = newPassController.text;
                debugPrint("Changing password from $oldPass to $newPass");

                // Simulate success
                Navigator.pop(ctx);
                final height = MediaQuery.of(context).size.height;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password changed successfully'),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: height - 100,
                      left: 20,
                      right: 20,
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    bool isScreenshotTaken = false;

    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New User',
                  style: AppTextStyle.titleMediumStyle(context),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Before submit, take screenshot and send to user.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (localError != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Text(
                      localError!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: passController,
                      obscureText: false,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Password is strictly visible',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 chars';
                        return null;
                      },
                    ),
                    SizedBox(height: 8.h),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Screenshot Taken',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        'Toggle ON to enable submit',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      value: isScreenshotTaken,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() {
                          isScreenshotTaken = val;
                          if (val) localError = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!isScreenshotTaken) {
                    setState(() {
                      localError = 'Pahle screenshot lelo fir switch on kar lo';
                    });
                    return;
                  }

                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final password = passController.text;

                    // Close dialog first
                    Navigator.pop(ctx);

                    final height = MediaQuery.of(context).size.height;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Creating user...'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: height - 100,
                          left: 20,
                          right: 20,
                        ),
                      ),
                    );

                    // Call Controller to create user
                    final success = await context
                        .read<AdminController>()
                        .createUser(name, email, password);

                    if (context.mounted) {
                      if (success) {
                        final height = MediaQuery.of(context).size.height;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('User created successfully!'),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: height - 100,
                              left: 20,
                              right: 20,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh stats
                        context.read<AdminController>().fetchStats();
                      } else {
                        final error = context
                            .read<AdminController>()
                            .errorMessage;
                        final height = MediaQuery.of(context).size.height;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? 'Failed to create user.'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: height - 100,
                              left: 20,
                              right: 20,
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add User'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool loading = false,
  }) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkTheme
                ? Colors.black26
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          loading
              ? SizedBox(
                  height: 20.h,
                  width: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: REdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDarkTheme ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkTheme
                  ? Colors.black26
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.isDarkTheme ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.isDarkTheme ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      color: Theme.of(context).cardTheme.color,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50.h,
                height: 50.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.isDarkTheme
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.isDarkTheme
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
