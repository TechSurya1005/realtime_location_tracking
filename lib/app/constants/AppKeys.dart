import 'package:flutter/material.dart';

class AppKeys {
  // ------------------------------------------------------------
  // 🔐 Shared Preferences: User & Auth Keys
  // ------------------------------------------------------------
  static const String appTheme = "appTheme";
  static const Brightness appThemeValue = Brightness.dark;

  // ------------------------------------------------------------
  // 🔐 Shared Preferences: User & Auth Keys
  // ------------------------------------------------------------
  static const String userLoginToken = 'user_login_token';
  static const String countryCode = 'country_code';
  static const String isLoggedIn = 'is_location_logged_in';
  static const String isGuestMode = 'is_location_guest_mode';

  // ------------------------------------------------------------
  // 🏪 Shared Preferences: User Data Keys
  // ------------------------------------------------------------

  static const String userId = 'user_id';
  static const String userAuthUid = 'user_auth_uid';
  static const String userRole = 'user_role';
  static const String userEmail = 'user_email';
  static const String userFullName = 'user_full_name';
  static const String userCreatedAt = 'user_created_at';
  static const String userUpdatedAt = 'user_updated_at';
}
