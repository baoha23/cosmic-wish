import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/update_service.dart';
import '../state/update_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';

/// Zero-footprint listener layered onto the home Stack. Prompts once
/// per launch when an update is available and not skipped.
class UpdatePrompt extends StatefulWidget {
  const UpdatePrompt({super.key});

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  bool _prompted = false;

  @override
  Widget build(BuildContext context) {
    final updateState = context.watch<UpdateState>();
    if (!_prompted && updateState.shouldPrompt) {
      _prompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<UpdateState>().shouldPrompt) {
          showUpdateDialog(context);
        }
      });
    }
    return const SizedBox.shrink();
  }
}

/// Three-phase update dialog: available → downloading → install
/// consent / error. Closing during download cancels the transfer.
Future<void> showUpdateDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _UpdateDialog(),
  );
}

enum _Phase { available, downloading, installing, failed }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog();

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  _Phase _phase = _Phase.available;
  int _percent = 0;
  http.Client? _downloadClient;

  AppRelease get _release =>
      context.read<UpdateState>().availableUpdate!;

  @override
  void dispose() {
    _downloadClient?.close();
    super.dispose();
  }

  Future<void> _startDownload(AppLocalizations l) async {
    setState(() => _phase = _Phase.downloading);
    final client = http.Client();
    _downloadClient = client;
    final service = context.read<UpdateState>().service;
    try {
      final apk = await service.downloadApk(
        _release,
        downloadClient: client,
        onProgress: (received, total) {
          if (!mounted || total == null || total <= 0) return;
          setState(() => _percent = (received * 100 / total).round());
        },
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.installing);
      await service.installApk(apk);
      // The installer takes over; on refusal we simply fall back to
      // the available phase so the user can retry from the dialog.
      if (mounted) setState(() => _phase = _Phase.available);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  void _cancelDownload() {
    _downloadClient?.close();
    _downloadClient = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.plum,
      title: Text(
        switch (_phase) {
          _Phase.available ||
          _Phase.installing => l.updateAvailableTitle(_release.versionName),
          _Phase.downloading => l.updateDownloading(_percent),
          _Phase.failed => l.updateFailed,
        },
        style: AppText.heading(18),
      ),
      content: switch (_phase) {
        _Phase.available => _availableContent(context, l),
        _Phase.downloading => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: _percent / 100,
              color: AppColors.gold,
              backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            ),
          ],
        ),
        _Phase.installing => Text(
          l.updateInstallConsent,
          style: AppText.body(14, color: AppColors.parchment),
        ),
        _Phase.failed => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.updateFailed, style: AppText.body(14)),
            const SizedBox(height: 12),
            MysticButton(label: l.updateRetry, onPressed: () => _startDownload(l)),
          ],
        ),
      },
      actions: switch (_phase) {
        _Phase.available => [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l.updateLater,
                style: AppText.body(14, color: AppColors.parchment),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<UpdateState>().skipCurrentRelease();
                Navigator.of(context).pop();
              },
              child: Text(
                l.updateSkipVersion,
                style: AppText.body(12, color: AppColors.ash),
              ),
            ),
            TextButton(
              onPressed: () => _startDownload(l),
              child: Text(
                l.updateNow,
                style: AppText.button(),
              ),
            ),
          ],
        _Phase.downloading => [
            TextButton(
              onPressed: _cancelDownload,
              child: Text(
                l.cancel,
                style: AppText.body(14, color: AppColors.parchment),
              ),
            ),
          ],
        _ => const <Widget>[],
      },
    );
  }

  Widget _availableContent(BuildContext context, AppLocalizations l) {
    final notes = _release.notes;
    if (notes == null || notes.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.updateWhatsNew,
          style: AppText.body(12, color: AppColors.gold),
        ),
        const SizedBox(height: 4),
        Text(notes, style: AppText.body(14, color: AppColors.parchment)),
      ],
    );
  }
}
