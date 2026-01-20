import 'package:flutter/material.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppSizes.dart';


class AppDecorations {
  static BoxDecoration topRoundedContainer({
    Color? color,
    double radius = AppSizes.cardRadiusMd,
  }) {
    return BoxDecoration(
      color: color ?? Colors.grey.shade50,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
    );
  }

  static BoxDecoration allRoundedContainer({
    Color? color,
    double radius = AppSizes.cardElevationSm,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
    );
  }



  static BoxDecoration commonCardDecoration({
    double borderRadius = AppSizes.cardRadiusMd,
    Color backgroundColor = AppColors.darkCardBackground,
    Color borderColor = AppColors.border,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      color: backgroundColor,
    );
  }

}
