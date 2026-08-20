import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/mystic_button.dart';
import '../widgets/starfield_background.dart';

/// OpenAI-compatible provider presets. Picking one fills the base URL
/// and model fields; "Custom" leaves them alone.
class _Preset {
  const _Preset(this.name, this.baseUrl, this.model);
  final String name;
  final String? baseUrl;
  final String? model;
}

const _presets = <_Preset>[
  _Preset('MiniMax', 'https://api.minimax.io/v1/chat/completions', 'MiniMax-M2.7'),
  _Preset('OpenAI', 'https://api.openai.com/v1/chat/completions', 'gpt-4o-mini'),
  _Preset(
    'OpenRouter',
    'https://openrouter.ai/api/v1/chat/completions',
    'anthropic/claude-sonnet-4.5',
  ),
  _Preset(
    'Gemini',
    'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
    'gemini-2.0-flash',
  ),
  _Preset(
    'GLM (Zhipu)',
    'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    'glm-4-flash',
  ),
  _Preset(
    'Kimi (Moonshot)',
    'https://api.moonshot.cn/v1/chat/completions',
    'moonshot-v1-8k',
  ),
  _Preset('Custom', null, null),
];

/// Admin console: view and edit the AI provider config stored in the
/// backend `app_config` table, test it live, or reset to server env
/// defaults. Changes propagate to wish generation within ~1 minute.
class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscureKey = true;
  String? _loadError;
  String? _notice;
  AdminTestResult? _testResult;
  AdminConfig? _config;
  String _presetName = 'Custom';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final config = await widget.service.getConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _baseUrlController.text = config.baseUrl;
        _modelController.text = config.model;
        _presetName = _presetFor(config.baseUrl, config.model);
        _loading = false;
        _loadError = null;
      });
    } on AdminAuthException {
      _backToLogin();
    } on AdminException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = l.adminNetworkError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = l.adminNetworkError;
      });
    }
  }

  String _presetFor(String baseUrl, String model) {
    for (final p in _presets) {
      if (p.baseUrl == baseUrl && p.model == model) return p.name;
    }
    return 'Custom';
  }

  void _backToLogin() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _notice = null;
    });
    try {
      await widget.service.saveConfig(
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        apiKey: _apiKeyController.text,
      );
      _apiKeyController.clear();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _notice = l.adminSaved);
    } on AdminAuthException {
      _backToLogin();
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() => _notice = e.code == 'invalid-base-url'
          ? '${l.adminBaseUrl}: ${e.code}'
          : e.toString());
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = l.adminNetworkError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    if (_testing) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final result = await widget.service.testConnection(
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
        apiKey: _apiKeyController.text,
      );
      if (!mounted) return;
      setState(() => _testResult = result);
    } on AdminAuthException {
      _backToLogin();
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() => _testResult = AdminTestResult(
        ok: false,
        latencyMs: 0,
        error: e.toString(),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _testResult = AdminTestResult(
        ok: false,
        latencyMs: 0,
        error: l.adminNetworkError,
      ));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.midnight,
        title: Text(l.adminResetConfirmTitle, style: AppText.heading(18)),
        content: Text(l.adminResetConfirmMessage, style: AppText.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel, style: AppText.body(14, color: AppColors.ash)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete, style: AppText.body(14, color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.resetConfig();
      await _load();
    } on AdminAuthException {
      _backToLogin();
    } catch (_) {
      if (mounted) setState(() => _notice = l.adminNetworkError);
    }
  }

  void _applyPreset(String? name) {
    if (name == null) return;
    setState(() => _presetName = name);
    for (final p in _presets) {
      if (p.name == name && p.baseUrl != null) {
        _baseUrlController.text = p.baseUrl!;
        _modelController.text = p.model!;
      }
    }
  }

  String _formatUpdatedAt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: StarfieldBackground(
        starCount: 160,
        twinkleSpeed: 1.0,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l.adminTitle),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : _loadError != null
                        ? _buildError(l)
                        : _buildForm(context, l),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_loadError!, style: AppText.body(14, color: AppColors.ash)),
          const SizedBox(height: 16),
          MysticButton(label: l.tryAgain, onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        _SectionHeader(l.adminMode),
        _modeBadge(l),
        const SizedBox(height: 24),
        _SectionHeader(l.adminPreset),
        _presetDropdown(l),
        const SizedBox(height: 24),
        _SectionHeader(l.adminBaseUrl),
        _field(
          controller: _baseUrlController,
          hint: 'https://…/v1/chat/completions',
          onChanged: () => setState(() => _presetName =
              _presetFor(_baseUrlController.text, _modelController.text)),
        ),
        const SizedBox(height: 16),
        _SectionHeader(l.adminModel),
        _field(
          controller: _modelController,
          hint: 'model-name',
          onChanged: () => setState(() => _presetName =
              _presetFor(_baseUrlController.text, _modelController.text)),
        ),
        const SizedBox(height: 16),
        _SectionHeader(l.adminApiKey),
        _apiKeyField(l),
        const SizedBox(height: 28),
        if (_notice != null) ...[
          Text(
            _notice!,
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.gold),
          ),
          const SizedBox(height: 12),
        ],
        if (_testResult != null) ...[
          _testResultBadge(l),
          const SizedBox(height: 12),
        ],
        _testing
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : MysticButton(
                label: l.adminTestConnection,
                onPressed: _test,
                expand: true,
              ),
        const SizedBox(height: 12),
        _saving
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : MysticButton(
                label: l.adminSave,
                onPressed: _save,
                expand: true,
              ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reset,
          child: Text(
            l.adminReset,
            style: AppText.body(13, color: AppColors.ash),
          ),
        ),
      ],
    );
  }

  Widget _modeBadge(AppLocalizations l) {
    final isDb = _config?.mode == 'database';
    final label = isDb
        ? l.adminModeDatabase(_formatUpdatedAt(_config?.updatedAt))
        : l.adminModeFallback;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppText.body(13, color: AppColors.gold),
      ),
    );
  }

  Widget _presetDropdown(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.plum.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _presetName,
          isExpanded: true,
          dropdownColor: AppColors.midnight,
          style: AppText.body(15),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          items: [
            for (final p in _presets)
              DropdownMenuItem(
                value: p.name,
                child: Text(p.name == 'Custom' ? l.adminPresetCustom : p.name),
              ),
          ],
          onChanged: _applyPreset,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      style: AppText.body(15),
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(13, color: AppColors.smoke),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.plum.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _apiKeyField(AppLocalizations l) {
    final masked = _config?.apiKeyMasked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          style: AppText.body(15),
          decoration: InputDecoration(
            hintText: masked != null
                ? l.adminApiKeyKeep(masked)
                : l.adminApiKeyNone,
            hintStyle: AppText.body(12, color: AppColors.smoke),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey ? Icons.visibility_off : Icons.visibility,
                color: AppColors.ash,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: AppColors.plum.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _testResultBadge(AppLocalizations l) {
    final r = _testResult!;
    if (r.ok) {
      final preview = r.replyPreview;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.plum.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.adminTestOk(r.latencyMs),
              style: AppText.body(14, color: AppColors.gold),
            ),
            if (preview != null && preview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '"$preview"',
                  style: AppText.body(12, color: AppColors.ash),
                ),
              ),
          ],
        ),
      );
    }
    final detail = r.error ?? (r.status != null ? 'HTTP ${r.status}' : '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.plum.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ash.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.adminTestFailed,
            style: AppText.body(14, color: AppColors.parchment),
          ),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                detail,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(12, color: AppColors.ash),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.parchment),
            tooltip: l.back,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.heading(20),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Text(
        title.toUpperCase(),
        style: AppText.body(
          12,
        ).copyWith(color: AppColors.gold, letterSpacing: 2),
      ),
    );
  }
}
