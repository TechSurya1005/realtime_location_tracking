import 'package:flutter/material.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';

/// Reusable primary button used across the app.
///
/// Usage:
/// ```dart
/// PrimaryButton(
///   text: 'Login',
///   loading: _loading,
///   onPressed: _onLogin,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool loading;
  final double height;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const PrimaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.loading = false,
    this.height = 52.0,
    this.backgroundColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.buttonPrimary;
    final ts =
        textStyle ??
        AppTextStyle.labelMediumStyle(
          context,
        ).copyWith(color: AppColors.textDark);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              )
            : Text(text, style: ts),
      ),
    );
  }
}
