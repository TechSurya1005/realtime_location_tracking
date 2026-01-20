import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/features/home/home_controller.dart';
import 'package:realtime_location_tracking/app/widgets/primary_button.dart';
import 'package:realtime_location_tracking/app/routes/app_routes.dart';
import 'package:realtime_location_tracking/features/location/location_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _meetingWithController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstLoadSafe(context);
    });
  }

  // Future<void> firstLoad() async {
  //   final controller = context.read<LocationController>();
  //   await controller.checkAndRestoreState();
  //   if (!controller.liveShareRunning) {
  //     await controller.startLiveShare();
  //   }
  // }

  Future<void> firstLoadSafe(BuildContext context) async {
    final controller = context.read<LocationController>();

    // already running → kuch mat karo
    if (controller.liveShareRunning) return;

    try {
      await controller.startLiveShare(context);
    } catch (e) {
      debugPrint('❌ firstLoadSafe error: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _meetingWithController.dispose();
    _mobileController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit app'),
        content: const Text('Do you really want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: AppTextStyle.bodyLargeStyle(context),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.primary, size: 22)
              : null,
          labelStyle: AppTextStyle.bodyMediumStyle(
            context,
          ).copyWith(color: AppColors.subTitle),
          hintStyle: AppTextStyle.bodySmallStyle(
            context,
          ).copyWith(color: AppColors.hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showBackDialog() ?? false;
        if (context.mounted && shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
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
                'Meeting Report',
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
                    'BCH Marketing',
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
              icon: Icons.history_rounded,
              onTap: () => context.pushNamed(AppRouteNames.submitted),
            ),
            const SizedBox(width: 12),
            _buildRoundAction(
              icon: Icons.account_circle_rounded,
              onTap: () => context.pushNamed(AppRouteNames.profile),
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
        body: SafeArea(
          child: Consumer<HomeController>(
            builder: (context, ctrl, _) {
              return RefreshIndicator(
                onRefresh: () async {
                  firstLoadSafe(context);
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Meeting Title',
                          prefixIcon: Icons.title_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter meeting title'
                              : null,
                        ),
                        _buildTextField(
                          controller: _dateController,
                          label: 'Visit Date',
                          prefixIcon: Icons.calendar_today_rounded,
                          readOnly: true,
                          onTap: () async {
                            final now = DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              ctrl.setVisitDate(pickedDate);
                              _dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(pickedDate);
                            }
                          },
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Select a date' : null,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'Visit City',
                                prefixIcon: Icons.location_city_rounded,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter city'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _areaController,
                                label: 'Visit Area',
                                prefixIcon: Icons.map_rounded,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter area'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          controller: _meetingWithController,
                          label: 'Meeting With',
                          hint: 'Person name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter person name'
                              : null,
                        ),
                        _buildTextField(
                          controller: _mobileController,
                          label: 'Mobile Number',
                          prefixIcon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter mobile number'
                              : null,
                        ),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Meeting Summary',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter summary'
                              : null,
                        ),
                        // // Image Picker Section
                        // Container(
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(12),
                        //     border: Border.all(
                        //       color: AppColors.primary.withOpacity(0.1),
                        //     ),
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         'Attachments',
                        //         style: AppTextStyle.titleSmallStyle(context)
                        //             .copyWith(
                        //               color: AppColors.primary,
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //       ),
                        //       const SizedBox(height: 12),
                        //       Row(
                        //         children: [
                        //           _buildImageActionCard(
                        //             icon: Icons.photo_library_outlined,
                        //             label: 'Gallery',
                        //             onTap: () => ctrl.pickImages(),
                        //           ),
                        //           const SizedBox(width: 12),
                        //           _buildImageActionCard(
                        //             icon: Icons.camera_alt_outlined,
                        //             label: 'Camera',
                        //             onTap: () => ctrl.pickFromCamera(),
                        //           ),
                        //         ],
                        //       ),
                        //       if (ctrl.images.isNotEmpty) ...[
                        //         const SizedBox(height: 16),
                        //         SizedBox(
                        //           height: 100,
                        //           child: ListView.separated(
                        //             scrollDirection: Axis.horizontal,
                        //             itemCount: ctrl.images.length,
                        //             separatorBuilder: (_, __) =>
                        //                 const SizedBox(width: 10),
                        //             itemBuilder: (context, index) {
                        //               final img = ctrl.images[index];
                        //               return Stack(
                        //                 children: [
                        //                   ClipRRect(
                        //                     borderRadius: BorderRadius.circular(
                        //                       12,
                        //                     ),
                        //                     child: Image.file(
                        //                       File(img.path),
                        //                       fit: BoxFit.cover,
                        //                       width: 100,
                        //                       height: 100,
                        //                     ),
                        //                   ),
                        //                   Positioned(
                        //                     top: 4,
                        //                     right: 4,
                        //                     child: GestureDetector(
                        //                       onTap: () =>
                        //                           ctrl.removeImageAt(index),
                        //                       child: Container(
                        //                         padding: const EdgeInsets.all(
                        //                           4,
                        //                         ),
                        //                         decoration: const BoxDecoration(
                        //                           color: Colors.black54,
                        //                           shape: BoxShape.circle,
                        //                         ),
                        //                         child: const Icon(
                        //                           Icons.close,
                        //                           size: 14,
                        //                           color: Colors.white,
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ),
                        //                 ],
                        //               );
                        //             },
                        //           ),
                        //         ),
                        //       ],
                        //     ],
                        //   ),
                        // ),
                        const SizedBox(height: 15),
                        PrimaryButton(
                          text: 'Submit Report',
                          loading: ctrl.isLoading,
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            ctrl.setTitle(_titleController.text.trim());
                            ctrl.setDescription(
                              _descriptionController.text.trim(),
                            );
                            ctrl.setVisitCity(_cityController.text.trim());
                            ctrl.setVisitArea(_areaController.text.trim());
                            ctrl.setMeetingWith(
                              _meetingWithController.text.trim(),
                            );
                            ctrl.setMobileNumber(_mobileController.text.trim());

                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await ctrl.submitReport();
                            if (!mounted) return;

                            if (ok) {
                              _formKey.currentState!.reset();
                              _titleController.clear();
                              _descriptionController.clear();
                              _cityController.clear();
                              _areaController.clear();
                              _meetingWithController.clear();
                              _mobileController.clear();
                              _dateController.clear();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Report submitted successfully!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.successColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Failed to submit report',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.errorColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyle.bodySmallStyle(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
