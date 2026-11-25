import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'theme.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;
  final bool hasUpdate;
}

class AvailableUpdateNotifier extends Notifier<AppUpdateInfo?> {
  @override
  AppUpdateInfo? build() => null;

  void setUpdate(AppUpdateInfo? info) => state = info;
  void dismiss() => state = null;
}

/// Reactive provider for application updates across screens.
final availableUpdateProvider =
    NotifierProvider<AvailableUpdateNotifier, AppUpdateInfo?>(
  AvailableUpdateNotifier.new,
);

class UpdateCheckerService {
  /// Versi aplikasi saat ini. Selalu disinkronkan dengan pubspec.yaml.
  static const currentVersion = '2.2.33';

  static const MethodChannel _channel =
      MethodChannel('com.example.ritme/app_utils');

  static const String _primaryApi =
      'https://api.github.com/repos/valynlove/lunera/releases/latest';
  static const String _fallbackApi =
      'https://api.github.com/repos/hyenavia/lunera/releases/latest';

  static const String _directDownloadUrl =
      'https://github.com/valynlove/lunera/releases/latest/download/Lunera.apk';

  static String? _promptedVersion;
  static bool _isShowingDialog = false;

  /// Memastikan URL eksternal menggunakan HTTPS dan berasal dari domain GitHub terpercaya.
  static bool isTrustedExternalUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        !uri.hasAuthority) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == 'github.com' ||
        host.endsWith('.github.com') ||
        host == 'githubusercontent.com' ||
        host.endsWith('.githubusercontent.com');
  }

  /// Membuka URL di browser atau installer eksternal.
  static Future<void> openUrl(String url) async {
    if (kIsWeb) return;
    final clean = url.trim();
    if (!isTrustedExternalUrl(clean)) {
      debugPrint('Blocked untrusted external URL: $clean');
      return;
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('openUrl', {'url': clean});
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        await Process.run('cmd', ['/c', 'start', '', clean]);
      }
    } catch (e) {
      debugPrint('Failed to open URL via native: $e');
    }
  }

  /// Memeriksa pembaruan dan otomatis memicu notifikasi serta memperbarui provider reaktif.
  static Future<AppUpdateInfo?> checkAndNotify(
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    final info = await checkForUpdate();
    if (info != null && info.hasUpdate) {
      ref.read(availableUpdateProvider.notifier).setUpdate(info);

      if (context != null &&
          _promptedVersion != info.latestVersion &&
          !_isShowingDialog) {
        if (context.mounted) {
          _promptedVersion = info.latestVersion;
          showUpdateDialog(context, info);
        }
      }
    }
    return info;
  }

  /// Memeriksa apakah ada pembaruan rilis terbaru di GitHub.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final data = await _fetchReleaseData(_primaryApi) ??
          await _fetchReleaseData(_fallbackApi);
      if (data == null) return null;

      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseName = (data['name'] as String? ?? 'Lunera $rawTag').trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();
      final releasePageUrl = (data['html_url'] as String? ?? '').trim();

      var downloadUrl = _directDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        String? arm64Url;
        String? fallbackUrl;
        for (final a in assets) {
          final assetName = (a['name'] as String? ?? '').toLowerCase();
          final url = a['browser_download_url'] as String?;
          if (url == null) continue;
          if (assetName == 'lunera.apk' || assetName == 'app-release.apk') {
            downloadUrl = url;
            arm64Url = null;
            fallbackUrl = null;
            break;
          } else if (arm64Url == null && assetName.endsWith('_arm64-v8a.apk')) {
            arm64Url = url;
          } else if (fallbackUrl == null && assetName.endsWith('.apk')) {
            fallbackUrl = url;
          }
        }
        downloadUrl = arm64Url ?? fallbackUrl ?? downloadUrl;
      }

      final hasUpdate = _isVersionGreater(cleanTag, currentVersion);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: cleanTag,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        releasePageUrl: releasePageUrl,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchReleaseData(String apiUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(apiUrl));
      request.headers.set('User-Agent', 'Lunera-Android/$currentVersion');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Membandingkan dua nomor versi SemVer (misal "1.0.1" > "1.0.0").
  static bool _isVersionGreater(String remote, String current) {
    if (remote.isEmpty) return false;
    final rParts = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (rParts.length < 3) {
      rParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false;
  }

  /// Memeriksa update dan langsung memunculkan dialog/snackbar.
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    WidgetRef? ref,
    bool silentIfUpToDate = false,
  }) async {
    final info = await checkForUpdate();
    if (ref != null && info != null && info.hasUpdate) {
      ref.read(availableUpdateProvider.notifier).setUpdate(info);
    }
    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      showUpdateDialog(context, info);
    } else if (!silentIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('You are using the latest version of Lunera (v{0}). ✨',
                [currentVersion]),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Menampilkan dialog pembaruan aplikasi berestetika Arcane Astral & Midnight UI.
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    _isShowingDialog = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: dark ? C.deepCard : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: C.lavender.withValues(alpha: dark ? 0.28 : 0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (dark ? C.voidBg : Colors.black12)
                        .withValues(alpha: 0.50),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                  if (dark)
                    BoxShadow(
                      color: C.aurora.withValues(alpha: 0.16),
                      blurRadius: 30,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Glowing Emblem and Titles
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              C.aurora.withValues(alpha: 0.32),
                              C.magenta.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: C.lavender.withValues(alpha: 0.42),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: C.aurora.withValues(alpha: 0.24),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.sparkles,
                            color: dark ? C.coral : C.aurora,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Update Available!'),
                              style: display(22,
                                  color: dark ? Colors.white : C.midnight),
                            ),
                            const SizedBox(height: 4),
                            // Version Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: dark
                                    ? C.nebula.withValues(alpha: 0.8)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: C.lavender.withValues(alpha: 0.32),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'v${info.currentVersion}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    LucideIcons.arrowRight,
                                    size: 12,
                                    color: C.coral,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'v${info.latestVersion}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: dark ? C.coral : C.aurora,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('A new version of Lunera is ready with the latest improvements:'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                          (dark ? C.mist : C.midnight).withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (info.releaseNotes.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? C.midnight : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              C.lavender.withValues(alpha: dark ? 0.22 : 0.16),
                        ),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            info.releaseNotes,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: (dark ? C.mist : C.midnight)
                                  .withValues(alpha: 0.90),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    tr('Tap "Update Now" to download and install the new APK.'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color:
                          (dark ? C.mist : C.midnight).withValues(alpha: 0.58),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          backgroundColor: dark
                              ? C.nebula.withValues(alpha: 0.42)
                              : Colors.grey.shade50,
                          side: BorderSide(
                            color: (dark ? C.lavender : C.midnight)
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          tr('Later'),
                          style: TextStyle(
                            color: dark ? C.mist : C.midnight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        icon: const Icon(LucideIcons.download, size: 18),
                        label: Text(
                          tr('Update Now'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: C.aurora,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: C.aurora.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          openUrl(info.downloadUrl);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _isShowingDialog = false;
    });
  }
}
