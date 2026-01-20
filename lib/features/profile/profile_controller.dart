import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ProfileController extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppKeys.userId);

      if (userId == null) {
        _errorMessage = "User session not found";
        return false;
      }

      // 1. Verify Old Password (using trim)
      final cleanOld = oldPassword.trim();
      final oldHash = sha256.convert(utf8.encode(cleanOld)).toString();

      final userData = await Supabase.instance.client
          .from('users')
          .select('password')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) {
        _errorMessage = "User not found in database";
        return false;
      }

      final dbHash = userData['password']?.toString();
      if (dbHash != oldHash) {
        debugPrint("Hash Mismatch! DB: $dbHash, Computed: $oldHash");
        _errorMessage = "Incorrect old password";
        return false;
      }

      // 2. Hash New Password and Update
      final cleanNew = newPassword.trim();
      final newHash = sha256.convert(utf8.encode(cleanNew)).toString();

      // Perform update and verify row modification using .select()
      final updatedData = await Supabase.instance.client
          .from('users')
          .update({'password': newHash})
          .eq('id', userId)
          .select();

      if (updatedData.isEmpty) {
        _errorMessage = "Update failed: No rows changed. Check RLS policies.";
        debugPrint("Update error: No rows affected for ID $userId");
        return false;
      }

      debugPrint("✅ Password updated successfully for user $userId");
      return true;
    } catch (e) {
      debugPrint("❌ Change Password Error: $e");
      _errorMessage = "System Error: ${e.toString()}";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // For a custom table setup, normal forgot password usually requires an email service.
      // Here we can either:
      // 1. Trigger Supabase Auth Reset (if using Supabase Auth)
      // 2. Or since we are using 'users' table, maybe just notify that admin needs to reset it?

      // Let's try the official Supabase Auth way if applicable,
      // but the user seems to be using a custom 'users' table for everything.

      // For now, let's simulate sending a request or returning a message.
      await Future.delayed(const Duration(seconds: 1));

      // Note: Full implementation would depend on backend capability.
      // Displaying a message that helps the user.
      _errorMessage = "Please contact your Admin to reset your password.";
      return false; // Returning false because we don't have an automated reset here yet
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
