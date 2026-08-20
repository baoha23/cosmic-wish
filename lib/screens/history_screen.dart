import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/wish_history_entry.dart';
import '../state/app_state.dart';
import '../state/history_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/starfield_background.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final twinkleSpeed = context.watch<AppState>().animationSpeed;
    return Scaffold(
      body: Consumer<HistoryState>(
        builder: (context, historyState, child) {
          return StarfieldBackground(
            starCount: 180,
            twinkleSpeed: twinkleSpeed,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, historyState),
                  Expanded(child: _buildBody(context, historyState)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HistoryState historyState) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: l.back,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.parchment),
          ),
          Expanded(
            child: Text(
              l.history,
              textAlign: TextAlign.center,
              style: AppText.heading(20),
            ),
          ),
          IconButton(
            tooltip: l.importFile,
            onPressed: () => _import(context, historyState),
            icon: const Icon(Icons.file_download, color: AppColors.parchment),
          ),
          if (historyState.entries.isNotEmpty)
            IconButton(
              tooltip: l.exportFile,
              onPressed: () => historyState.exportToFile(),
              icon: const Icon(Icons.file_upload, color: AppColors.parchment),
            ),
          if (historyState.entries.isNotEmpty)
            IconButton(
              tooltip: l.deleteAll,
              onPressed: () => _confirmClearAll(context, historyState),
              icon: const Icon(Icons.delete_sweep, color: AppColors.parchment),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, HistoryState historyState) async {
    final l = AppLocalizations.of(context)!;
    try {
      final count = await historyState.importFromPicker();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(count > 0 ? l.imported(count) : l.noNewData)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
    }
  }

  Widget _buildBody(BuildContext context, HistoryState historyState) {
    final l = AppLocalizations.of(context)!;
    if (historyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (historyState.isEmpty) {
      return _buildEmpty(l);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: historyState.entries.length,
      itemBuilder: (context, index) {
        final entry = historyState.entries[index];
        return _HistoryCard(
              entry: entry,
              l: l,
              onDelete: () => historyState.remove(entry.id),
            )
            .animate(delay: (50 * index).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.gold.withValues(alpha: 0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            l.noWishesYet,
            style: AppText.heading(
              18,
            ).copyWith(color: AppColors.parchment.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            l.beginYourJourney,
            style: AppText.body(14).copyWith(
              color: AppColors.parchment.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    HistoryState historyState,
  ) async {
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.plum,
        title: Text(l.deleteAllConfirm, style: AppText.heading(20)),
        content: Text(
          l.deleteAllMessage,
          style: AppText.body(14).copyWith(color: AppColors.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: AppText.body(14).copyWith(color: AppColors.parchment),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: AppText.body(14).copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await historyState.clear();
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.l,
    required this.onDelete,
  });

  final WishHistoryEntry entry;
  final AppLocalizations l;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: AppColors.parchment),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(entry: entry),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.plum.withValues(alpha: 0.6),
            border: Border.all(
              color: entry.category.color.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.category.color.withValues(alpha: 0.2),
                      border: Border.all(
                        color: entry.category.color.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      entry.category.icon,
                      color: entry.category.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.category.label(l),
                          style: AppText.heading(
                            16,
                          ).copyWith(color: entry.category.color),
                        ),
                        Text(
                          _formatTime(entry.timestamp),
                          style: AppText.body(12).copyWith(
                            color: AppColors.parchment.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _JourneyBadge(entry: entry, l: l),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.parchment,
                    size: 20,
                  ),
                ],
              ),
              if (entry.transcript.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l.wishLabel,
                  style: AppText.body(12).copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"${entry.transcript}"',
                  style: AppText.body(14).copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.85),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.obsidian.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.response,
                  style: AppText.prophecy().copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inHours < 1) return l.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _JourneyBadge extends StatelessWidget {
  const _JourneyBadge({required this.entry, required this.l});
  final WishHistoryEntry entry;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final isReflected = entry.hasReflection;
    final color = isReflected
        ? AppColors.goldWhisper
        : AppColors.parchment.withValues(alpha: 0.45);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReflected ? Icons.auto_awesome : Icons.hourglass_empty,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isReflected ? l.journeyReflected : l.journeyPending,
            style: AppText.caption(
              11,
            ).copyWith(color: color, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
