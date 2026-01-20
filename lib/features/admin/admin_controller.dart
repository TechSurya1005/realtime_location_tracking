import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalReports;
  final int activeUsers;

  AdminDashboardStats({
    this.totalUsers = 0,
    this.totalReports = 0,
    this.activeUsers = 0,
  });
}

class AdminController extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  AdminDashboardStats _stats = AdminDashboardStats();
  AdminDashboardStats get stats => _stats;

  AdminController() {
    fetchStats();
  }

  Future<void> fetchStats() async {
    _loading = true;
    notifyListeners();

    try {
      // 1. Fetch total users
      final usersData = await Supabase.instance.client
          .from('users')
          .select('*');
      final totalUsers = (usersData as List).length;

      // 2. Fetch total reports
      final reportsData = await Supabase.instance.client
          .from('reports')
          .select('*');
      final totalReports = (reportsData as List).length;

      // 3. Fetch active users (unique users who have sent location history)
      final locationData = await Supabase.instance.client
          .from('location_history')
          .select('user_auth_uid');

      final activeUids = (locationData as List)
          .map((item) => item['user_auth_uid']?.toString())
          .where((uid) => uid != null)
          .toSet();
      final activeUsers = activeUids.length;

      _stats = AdminDashboardStats(
        totalUsers: totalUsers,
        totalReports: totalReports,
        activeUsers: activeUsers,
      );
    } catch (e) {
      debugPrint("Admin Stats Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllUsers() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      _users = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Fetch User List Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllReports() async {
    _loading = true;
    notifyListeners();
    try {
      // Fetching reports and joining with users to get the name
      // Note: This logic assumes that reports.user_auth_uid matches users.id
      final data = await Supabase.instance.client
          .from('reports')
          .select('*, users(full_name)')
          .order('created_at', ascending: false);

      _reports = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Fetch Reports Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(String name, String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      _errorMessage = null;
      // 1️⃣ Hash password (as you want)
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      // 2️⃣ Call RPC (admin-only)
      await Supabase.instance.client.rpc(
        'create_user_by_admin',
        params: {
          'full_name': name,
          'email': email,
          'password': hashedPassword,
          'role': 'user',
        },
      );

      debugPrint('✅ User created by admin');
      return true;
    } catch (e) {
      debugPrint('❌ Create User Error: $e');
      if (e.toString().contains('already exists') ||
          e.toString().contains('23505')) {
        _errorMessage = "This email is already registered.";
      } else {
        _errorMessage = e.toString();
      }
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
