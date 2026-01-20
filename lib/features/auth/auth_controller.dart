import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthController extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _setLoading(true);
    try {
      // Hash the password using SHA-256
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();
      // Query the 'users' table directly with the hashed password
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (data == null) {
        return null; // Login failed
      }

      // Login Successful - Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppKeys.isLoggedIn, true);
      await prefs.setString(AppKeys.userId, data['id'].toString());
      await prefs.setString(AppKeys.userAuthUid, data['auth_uid'] ?? '');
      await prefs.setString(AppKeys.userEmail, data['email'] ?? '');
      await prefs.setString(AppKeys.userFullName, data['full_name'] ?? '');

      final role = data['role'] as String?;
      if (role != null) {
        await prefs.setString(AppKeys.userRole, role);
      }

      return data;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Also sign out from Supabase if using valid auth session
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
