import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';
import 'admin_config_screen.dart';

/// Password gate for the hidden admin console. The session token is
/// held by the in-memory [AdminService] passed through to the config
/// screen — nothing is persisted on device.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _controller = TextEditingController();
  final _service = AdminService();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    final password = _controller.text;
    if (password.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.login(password);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminConfigScreen(service: _service)),
      );
    } on AdminException catch (e) {
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'rate-limit-exceeded' => l.adminRateLimited,
          'admin-not-configured' => l.adminNotConfigured,
          _ => l.adminLoginFailed,
        };
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = l.adminNetworkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: StarfieldBackground(
        starCount: 160,
        twinkleSpeed: 1.0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                Text(l.adminLoginTitle, style: AppText.title()),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                  style: AppText.body(16),
                  decoration: InputDecoration(
                    hintText: l.adminPasswordHint,
                    hintStyle: AppText.body(14, color: AppColors.smoke),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.body(13, color: AppColors.ash),
                  ),
                const SizedBox(height: 24),
                _busy
                    ? const CircularProgressIndicator(color: AppColors.gold)
                    : MysticButton(
                        label: l.adminLoginButton,
                        onPressed: _submit,
                        expand: true,
                      ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
