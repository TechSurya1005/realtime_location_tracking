import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationHistoryController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;

  List<Map<String, dynamic>> _usersWithHistory = [];
  List<Map<String, dynamic>> get usersWithHistory => _usersWithHistory;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  void setDate(DateTime? date) {
    _selectedDate = date;
    _userHistoryMap.clear(); // Clear cached user histories
    fetchUsersWithHistory();
  }

  // Stores history per user: { user_auth_uid: [history_items] }
  Map<String, List<Map<String, dynamic>>> _userHistoryMap = {};
  Map<String, List<Map<String, dynamic>>> get userHistoryMap => _userHistoryMap;

  // Track which users are loading their history
  Map<String, bool> _historyLoadingMap = {};
  bool isHistoryLoading(String uid) => _historyLoadingMap[uid] ?? false;

  Future<void> fetchUsersWithHistory() async {
    _loading = true;
    notifyListeners();

    try {
      // Fetch user_auth_uid and user details from location_history
      // We use users(full_name, email) join.
      // Note: This might return many rows if history is large.
      // In a real app, you might use a more optimized query or RPC.
      var query = _supabase
          .from('location_history')
          .select('user_auth_uid, users(full_name, email), created_at');

      if (_selectedDate != null) {
        final start = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));

        query = query
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      final uniqueUsers = <String, Map<String, dynamic>>{};
      for (var item in (data as List)) {
        final uid = item['user_auth_uid'] as String?;
        if (uid != null && !uniqueUsers.containsKey(uid)) {
          final userData = item['users'];
          if (userData != null) {
            uniqueUsers[uid] = {
              'user_auth_uid': uid,
              'full_name': userData['full_name'],
              'email': userData['email'],
            };
          }
        }
      }
      _usersWithHistory = uniqueUsers.values.toList();
    } catch (e) {
      debugPrint("Fetch Users With History Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoryForUser(String uid) async {
    // If we already have it and it's not empty, maybe skip?
    // Or always refresh on expand. Let's always refresh for now.
    _historyLoadingMap[uid] = true;
    notifyListeners();

    try {
      var query = _supabase
          .from('location_history')
          .select('*')
          .eq('user_auth_uid', uid);

      if (_selectedDate != null) {
        final start = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));

        query = query
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      _userHistoryMap[uid] = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Fetch History For User ($uid) Error: $e");
    } finally {
      _historyLoadingMap[uid] = false;
      notifyListeners();
    }
  }
}
