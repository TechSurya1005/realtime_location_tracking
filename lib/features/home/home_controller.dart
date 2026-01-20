import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:realtime_location_tracking/features/reports/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

class HomeController extends ChangeNotifier {
  String description = '';
  List<XFile> images = [];
  bool isLoading = false;

  // Real data from Supabase
  List<Map<String, dynamic>> _userReports = [];
  List<Map<String, dynamic>> get userReports => _userReports;

  // In-memory list of submitted reports (legacy, keeping for compatibility if needed)
  final List<Report> submittedReports = [];

  String title = '';

  // New Fields
  DateTime? visitDate;
  String visitCity = '';
  String visitArea = '';
  String meetingWith = '';
  String mobileNumber = '';

  final ImagePicker _picker = ImagePicker();

  void setTitle(String v) {
    title = v;
    notifyListeners();
  }

  void setDescription(String v) {
    description = v;
    notifyListeners();
  }

  void setVisitDate(DateTime? v) {
    visitDate = v;
    notifyListeners();
  }

  void setVisitCity(String v) {
    visitCity = v;
    notifyListeners();
  }

  void setVisitArea(String v) {
    visitArea = v;
    notifyListeners();
  }

  void setMeetingWith(String v) {
    meetingWith = v;
    notifyListeners();
  }

  void setMobileNumber(String v) {
    mobileNumber = v;
    notifyListeners();
  }

  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        images.addAll(picked);
        notifyListeners();
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  /// Capture a single image using the device camera and add it to the list
  Future<void> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (picked != null) {
        images.add(picked);
        notifyListeners();
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> fetchUserReports() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userAuthUid = prefs.getString(AppKeys.userAuthUid);

      if (userAuthUid == null || userAuthUid.isEmpty) {
        debugPrint("User Auth UID not found in prefs");
        _userReports = [];
        return;
      }

      final data = await Supabase.instance.client
          .from('reports')
          .select('*')
          .eq('user_auth_uid', userAuthUid)
          .order('created_at', ascending: false);

      debugPrint("User Auth UID: $userAuthUid");
      debugPrint("User Reports: $data");

      _userReports = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Fetch User Reports Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    // If already under 500KB, return as is
    if (bytes.length <= 500 * 1024) return bytes;

    var quality = 90;
    Uint8List? compressed = bytes;

    while (quality > 10) {
      compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1080,
        minWidth: 1080,
        quality: quality,
      );
      if (compressed.length <= 500 * 1024) break;
      quality -= 10;
    }
    return compressed;
  }

  Future<bool> submitReport() async {
    if (title.trim().isEmpty || description.trim().isEmpty) return false;

    isLoading = true;
    notifyListeners();

    final supabase = Supabase.instance.client;
    final List<String> imageUrls = [];
    final List<String> uploadedPaths = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final userAuthUid = prefs.getString(AppKeys.userAuthUid);

      if (userAuthUid == null) {
        throw Exception("User session not found");
      }

      debugPrint("👤 User Auth UID: $userAuthUid");

      // 🔹 Upload images
      for (final file in images) {
        final compressed = await _compressImage(file);
        if (compressed == null) continue;

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

        final storagePath = 'reports/$fileName';

        final contentType = file.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';

        final uploadResult = await supabase.storage
            .from('surya')
            .uploadBinary(
              storagePath,
              compressed,
              fileOptions: FileOptions(contentType: contentType, upsert: false),
            );

        if (uploadResult.isEmpty) {
          throw Exception('Image upload failed for $storagePath');
        }

        uploadedPaths.add(storagePath);

        // Generate public URL
        final publicUrl = supabase.storage
            .from('surya')
            .getPublicUrl(storagePath);

        debugPrint('📸 Uploaded: $storagePath');
        debugPrint('🔗 Public URL: $publicUrl');

        imageUrls.add(publicUrl);
      }

      // ⏳ Small delay for CDN probagation
      await Future.delayed(const Duration(seconds: 2));

      // 🔹 Insert report with full URLs
      await supabase.from('reports').insert({
        'user_auth_uid': userAuthUid,
        'report_title': title.trim(),
        'meeting_summary': description.trim(),
        'visit_date': visitDate?.toIso8601String(),
        'visit_city': visitCity.trim(),
        'visit_area': visitArea.trim(),
        'meeting_with': meetingWith.trim(),
        'mobile_number': mobileNumber.trim(),
      });

      // Reset on success
      title = '';
      description = '';
      visitDate = null;
      visitCity = '';
      visitArea = '';
      meetingWith = '';
      mobileNumber = '';
      images.clear();

      await fetchUserReports();
      return true;
    } catch (e, stack) {
      debugPrint("❌ Submit Report Error: $e");
      debugPrint("📛 StackTrace: $stack");

      // 🔥 ROLLBACK STORAGE
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage.from('surya').remove(uploadedPaths);
          debugPrint("🧹 Rolled back ${uploadedPaths.length} files");
        } catch (cleanupError) {
          debugPrint("⚠️ Storage cleanup failed: $cleanupError");
        }
      }

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
