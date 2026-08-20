import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/supabase_config.dart';

/// A published release row in `app_releases`.
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.notes,
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? notes;

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
    versionCode: (json['version_code'] as num?)?.toInt() ?? 0,
    versionName: json['version_name'] as String? ?? '',
    apkUrl: json['apk_url'] as String? ?? '',
    notes: json['notes'] as String?,
  );
}

/// Thrown when the APK download fails or is cancelled. Partial files
/// are cleaned up before this surfaces.
class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks `app_releases` for a newer build, downloads the universal
/// APK with progress, and hands it to the system installer. The
/// version check never throws — an app that can't phone home simply
/// shows no update.
class UpdateService {
  UpdateService({
    this.restUrl = SupabaseConfig.restUrl,
    this.anonKey = SupabaseConfig.anonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String restUrl;

  /// Injectable so tests can exercise the fetch path; the shipped
  /// default is the build-time anon key (empty → checks are skipped).
  final String anonKey;
  final http.Client _client;

  static const _checkTimeout = Duration(seconds: 15);

  void dispose() => _client.close();

  /// Build number from pubspec (`1.1.0+1` → 1). This is the value
  /// `app_releases.version_code` is compared against.
  Future<int> currentVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  /// Display label for the running build (`Cosmic Wish v1.1.0`).
  Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return 'Cosmic Wish v${info.version}';
  }

  /// Newest release with `version_code` greater than
  /// [currentVersionCode], or null when up to date, unreachable,
  /// malformed, or running without an anon key. Never throws.
  Future<AppRelease?> fetchLatestUpdate({
    required int currentVersionCode,
  }) async {
    if (anonKey.isEmpty) return null;
    try {
      final r = await _client
          .get(
            Uri.parse('$restUrl/app_releases?order=version_code.desc&limit=1'),
            headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'},
          )
          .timeout(_checkTimeout);
      if (r.statusCode != 200) {
        debugPrint('[UPDATE] check failed: HTTP ${r.statusCode}');
        return null;
      }
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is! List || data.isEmpty) return null;
      final release = AppRelease.fromJson(data.first as Map<String, dynamic>);
      if (release.versionCode <= currentVersionCode || release.apkUrl.isEmpty) {
        return null;
      }
      return release;
    } catch (e) {
      debugPrint('[UPDATE] check error: $e');
      return null;
    }
  }

  /// Streams the release APK to app-private external storage,
  /// reporting (receivedBytes, totalBytesOrNull) along the way. A
  /// dedicated client is used so the caller can cancel the download
  /// by closing it. Throws [UpdateDownloadException] after removing
  /// any partial file.
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int? total)? onProgress,
    http.Client? downloadClient,
  }) async {
    final client = downloadClient ?? http.Client();
    final ownsClient = downloadClient == null;
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw const UpdateDownloadException(
        'Không có bộ nhớ ngoài để lưu bản cập nhật.',
      );
    }
    final file = File('${dir.path}/cosmic-wish-${release.versionName}.apk');
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(release.apkUrl)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw UpdateDownloadException(
          'Tải về thất bại (HTTP ${response.statusCode}).',
        );
      }
      final contentLength = response.contentLength;
      final total = contentLength != null && contentLength >= 0
          ? contentLength
          : null;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (total != null && received != total) {
        throw const UpdateDownloadException('Tải về chưa hoàn tất.');
      }
      return file;
    } catch (e) {
      // Clean up the partial file; a truncated APK must never reach
      // the installer.
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (e is UpdateDownloadException) rethrow;
      throw const UpdateDownloadException('Tải về thất bại.');
    } finally {
      if (ownsClient) client.close();
    }
  }

  /// Asks for REQUEST_INSTALL_PACKAGES (returns false when the user
  /// refuses), then opens the system installer for [apk]. The app
  /// process is killed on install, so there is no post-install step.
  Future<bool> installApk(File apk) async {
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      status = await Permission.requestInstallPackages.request();
    }
    if (!status.isGranted) {
      debugPrint('[UPDATE] install permission denied');
      return false;
    }
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      debugPrint('[UPDATE] open installer failed: ${result.message}');
      return false;
    }
    return true;
  }
}
