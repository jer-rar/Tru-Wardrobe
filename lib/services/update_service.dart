import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Mirrors TruBrief's OTA update flow verbatim (see articles_screen.dart
/// _checkForUpdate), pointed at tw_app_version instead of trl_app_version.
class UpdateService {
  static bool _updateDialogShown = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (!kReleaseMode) return;
    if (_updateDialogShown) return;
    try {
      final rows = await Supabase.instance.client
          .from('tw_app_version')
          .select()
          .order('version_code', ascending: false)
          .limit(1);
      if (rows.isEmpty) return;
      final latest = rows.first;
      final latestCode = (latest['version_code'] as num?)?.toInt() ?? 0;
      final latestName = latest['version_name']?.toString() ?? '';
      final downloadUrl = latest['download_url']?.toString() ?? '';
      final notes = latest['release_notes']?.toString() ?? '';
      final force = latest['force_update'] == true;
      if (latestCode <= kAppVersionCode || downloadUrl.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissedCode = prefs.getInt('update_dismissed_code') ?? 0;
      if (dismissedCode >= latestCode) return;
      if (!context.mounted) return;

      _updateDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: !force,
        builder: (ctx) {
          double progress = 0;
          bool downloading = false;
          return StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              backgroundColor: const Color(kCardColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Available',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Version $latestName is ready.',
                          style: const TextStyle(color: Colors.white70)),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(notes, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                      if (downloading) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: Colors.white12,
                          color: const Color(kAccentColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress >= 1.0
                              ? 'Installing...'
                              : progress > 0
                                  ? '${(progress * 100).toStringAsFixed(0)}%'
                                  : 'Downloading...',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (!force && !downloading)
                  TextButton(
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('update_dismissed_code', latestCode);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Later', style: TextStyle(color: Colors.white38)),
                  ),
                if (!downloading)
                  TextButton(
                    onPressed: () => _download(
                      ctx,
                      downloadUrl,
                      setStateDialog,
                      (v) => progress = v,
                      (v) => downloading = v,
                    ),
                    child: const Text('Update', style: TextStyle(color: Color(kAccentColor))),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  static Future<void> _download(
    BuildContext ctx,
    String downloadUrl,
    void Function(void Function()) setStateDialog,
    void Function(double) setProgress,
    void Function(bool) setDownloading,
  ) async {
    setStateDialog(() => setDownloading(true));
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/tru_wardrobe_update.apk';
      final file = File(filePath);
      if (await file.exists()) await file.delete();

      final ioClient = HttpClient();
      final ioReq = await ioClient.getUrl(Uri.parse(downloadUrl));
      ioReq.followRedirects = true;
      ioReq.maxRedirects = 10;
      ioReq.headers.set(HttpHeaders.userAgentHeader, 'TruWardrobe-Updater/1.0');
      ioReq.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      final ioResp = await ioReq.close();

      if (ioResp.statusCode < 200 || ioResp.statusCode >= 300) {
        throw Exception('Server returned ${ioResp.statusCode}');
      }

      final total = ioResp.contentLength;
      int received = 0;
      final sink = file.openWrite();
      await ioResp.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          setStateDialog(() => setProgress(received / total));
        }
      }).asFuture();
      await sink.flush();
      await sink.close();
      ioClient.close();

      final fileSize = await file.length();
      if (fileSize < 1000000) {
        throw Exception(
            'Download incomplete — only ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB received. Check your connection and try again.');
      }
      setStateDialog(() => setProgress(1.0));
      await Future.delayed(const Duration(milliseconds: 600));
      await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      debugPrint('Update download error: $e');
      if (ctx.mounted) {
        setStateDialog(() {
          setDownloading(false);
          setProgress(0);
        });
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: const Color(0xFF8B0000),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}
