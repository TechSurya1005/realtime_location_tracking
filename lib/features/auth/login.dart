import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realtime_location_tracking/app/routes/app_routes.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';
import 'package:realtime_location_tracking/core/utils.dart';
import 'package:realtime_location_tracking/app/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/features/auth/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter email';
    final email = v.trim();
    // Only allow Gmail addresses (case-insensitive)
    // Use a standard local-part character set and ensure proper end-anchor
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@gmail\.com$',
      caseSensitive: false,
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid Gmail address (example@gmail.com)';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _onLogin() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      showAppDialog(
        context,
        title: 'Warning',
        subtitle: 'Please fix the form errors before continuing.',
        dialogType: DialogType.warning,
        okButtonText: 'OK',
        showCancel: false,
      );
      return;
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authCtrl = context.read<AuthController>();
      final data = await authCtrl.login(email, password);

      if (data == null) {
        if (!mounted) return;
        showAppDialog(
          context,
          title: 'Error',
          subtitle: 'Invalid email or password',
          dialogType: DialogType.error,
          okButtonText: 'OK',
          showCancel: false,
        );
        return;
      }

      // Role based navigation is handled by data from controller
      final role = data['role'] as String?;

      if (!mounted) return;

      showAppDialog(
        context,
        title: 'Success',
        subtitle: 'Login successful',
        dialogType: DialogType.success,
        okButtonText: 'OK',
        showCancel: false,
        onOk: () {
          if (role == 'admin') {
            context.goNamed(AppRouteNames.adminHome);
          } else {
            context.goNamed(AppRouteNames.home);
          }
        },
      );
    } catch (e) {
      debugPrint("Login Error ===========> ${e.toString()}");
      if (!mounted) return;

      String errorMessage = 'Something went wrong. Please try again.';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('network request failed')) {
        errorMessage = 'Please check your internet connection.';
      } else if (errorString.contains('recursion')) {
        errorMessage =
            'Server configuration error. Please contact a system administrator.'; // Hinting at the RLS policy issue
      } else if (errorString.contains('postgrestexception')) {
        errorMessage = 'Database error occurred. Please try again later.';
      }

      showAppDialog(
        context,
        title: 'Error',
        subtitle: errorMessage,
        dialogType: DialogType.error,
        okButtonText: 'OK',
        showCancel: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: 24),

              // Illustration
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/images/login.png',
                  fit: BoxFit.contain,
                  // shows placeholder if asset missing
                  errorBuilder: (ctx, err, st) => Icon(
                    Icons.health_and_safety,
                    size: 120,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome Back',
                style: AppTextStyle.headlineMediumStyle(context),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Sign in to continue to your account',
                style: AppTextStyle.bodyMediumStyle(context),
              ),

              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: AppTextStyle.titleSmallStyle(context)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyle.labelSmallStyle(context),
                      decoration: InputDecoration(
                        hintText: 'your@gmail.com',

                        hintStyle: AppTextStyle.labelSmallStyle(
                          context,
                        ).copyWith(color: AppColors.hintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 12.0,
                        ),
                      ),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Password',
                      style: AppTextStyle.titleSmallStyle(context),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: AppTextStyle.labelSmallStyle(context),
                      maxLength: 8,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        counterText: '',
                        hintStyle: AppTextStyle.labelSmallStyle(
                          context,
                        ).copyWith(color: AppColors.hintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 12.0,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthController>(
                      builder: (context, authCtrl, child) {
                        return PrimaryButton(
                          text: 'Login',
                          loading: authCtrl.loading,
                          onPressed: _onLogin,
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
