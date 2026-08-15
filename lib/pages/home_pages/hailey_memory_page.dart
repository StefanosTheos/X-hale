import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/chat_service.dart';

class HaileyMemoryPage extends ConsumerStatefulWidget {
  final String userId;
  final String jwt;

  const HaileyMemoryPage({super.key, required this.userId, required this.jwt});

  @override
  ConsumerState<HaileyMemoryPage> createState() => _HaileyMemoryPageState();
}

class _HaileyMemoryPageState extends ConsumerState<HaileyMemoryPage> {
  List<Map<String, dynamic>> _facts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  Future<void> _loadFacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final facts = await ChatService.loadMemory(jwt: widget.jwt);
      if (mounted) setState(() => _facts = facts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFact(String factId) async {
    try {
      await ChatService.deleteFact(factId: factId, jwt: widget.jwt);
      if (mounted) {
        setState(() => _facts.removeWhere((f) => f['fact_id'] == factId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _confirmFact(String factId) async {
    try {
      final updated = await ChatService.confirmFact(
        factId: factId,
        jwt: widget.jwt,
      );
      if (mounted) {
        setState(() {
          final index = _facts.indexWhere((f) => f['fact_id'] == factId);
          if (index != -1) _facts[index] = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to confirm: $e')));
      }
    }
  }

  void _confirmDelete(String factId, String label) {
    final isDark = ref.read(userProvider.select((u) => u.theme == 'dark'));
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    isDark
                        ? AppThemes.darkDeleteDialogGradient
                        : AppThemes.lightDeleteDialogGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 36,
                    color:
                        isDark
                            ? AppThemes.darkDeleteButtonColor
                            : AppThemes.lightDeleteButtonColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Remove "$label"?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? AppThemes.darkTextColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hailey will no longer use this fact in conversations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppThemes.darkSubtitleColor : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.elevatedButtonBackground(
                            isDark,
                          ),
                          foregroundColor:
                              isDark ? AppThemes.darkTextColor : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteFact(factId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? AppThemes.darkDeleteButtonColor
                                  : AppThemes.lightDeleteButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _formatKey(String raw) => raw
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static const _typeLabels = <String, String>{
    'trigger': 'Triggers',
    'coping_strategy_validated': 'What helps you',
    'coping_strategy_failed': 'What hasn\'t helped',
    'nrt_use': 'NRT use',
    'social_context': 'Social context',
    'motivation': 'Motivations',
    'stage_of_change': 'Stage of change',
    'past_attempt_history': 'Past attempts',
    'physical_symptom_reported': 'Physical symptoms',
  };

  static const _typeIcons = <String, IconData>{
    'trigger': Icons.local_fire_department_outlined,
    'coping_strategy_validated': Icons.check_circle_outline,
    'coping_strategy_failed': Icons.cancel_outlined,
    'nrt_use': Icons.medication_outlined,
    'social_context': Icons.people_outline,
    'motivation': Icons.emoji_events_outlined,
    'stage_of_change': Icons.trending_up,
    'past_attempt_history': Icons.history,
    'physical_symptom_reported': Icons.favorite_border,
  };

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final fact in _facts) {
      final type = fact['fact_type'] as String? ?? 'other';
      groups.putIfAbsent(type, () => []).add(fact);
    }
    return groups;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Hailey\'s memory',
              style: TextStyle(
                color:
                    isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppThemes.darkMotivationGradient
                  : AppThemes.lightMotivationGradient,
        ),
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color:
              isDark ? AppThemes.darkDiaryTextColor : const Color(0xFF0077B6),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppThemes.darkSubtitleColor : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadFacts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_facts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 56,
                color: isDark ? AppThemes.darkSubtitleColor : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Hailey hasn\'t learned anything about you yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppThemes.darkSubtitleColor : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Have a few conversations and she\'ll start remembering your triggers, coping strategies, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppThemes.darkSubtitleColor : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _grouped;
    return RefreshIndicator(
      onRefresh: _loadFacts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Current facts help Hailey personalise your experience. Outdated facts are not used unless you confirm them. You can remove any fact at any time.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppThemes.darkSubtitleColor : Colors.black54,
              ),
            ),
          ),
          for (final entry in groups.entries) ...[
            _GroupHeader(
              label: _typeLabels[entry.key] ?? entry.key,
              icon: _typeIcons[entry.key] ?? Icons.info_outline,
              isDark: isDark,
            ),
            ...entry.value.map(
              (fact) => _FactTile(
                fact: fact,
                isDark: isDark,
                onDelete:
                    () => _confirmDelete(
                      fact['fact_id'] as String,
                      _formatKey(fact['fact_key'] as String? ?? 'fact'),
                    ),
                onConfirm: () => _confirmFact(fact['fact_id'] as String),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isDark ? AppThemes.darkDiaryTextColor : const Color(0xFF0077B6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color:
                  isDark
                      ? AppThemes.darkDiaryTextColor
                      : const Color(0xFF0077B6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.fact,
    required this.isDark,
    required this.onDelete,
    required this.onConfirm,
  });

  final Map<String, dynamic> fact;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final key = _HaileyMemoryPageState._formatKey(
      fact['fact_key'] as String? ?? '',
    );
    final value = fact['fact_value'] as String? ?? '';
    final confidence = (fact['confidence'] as num?)?.toDouble() ?? 0.0;
    final isStale = fact['is_stale'] == true;
    final lastConfirmed = DateTime.tryParse(
      fact['last_confirmed'] as String? ??
          fact['first_observed'] as String? ??
          '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppThemes.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppThemes.darkTextColor : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? AppThemes.darkSubtitleColor : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                _ConfidenceBar(confidence: confidence, isDark: isDark),
                const SizedBox(height: 5),
                Text(
                  lastConfirmed == null
                      ? 'Confirmation date unavailable'
                      : 'Last confirmed ${lastConfirmed.toLocal().day}/${lastConfirmed.toLocal().month}/${lastConfirmed.toLocal().year}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppThemes.darkSubtitleColor : Colors.black38,
                  ),
                ),
                if (isStale) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Outdated — Hailey is not using this fact. Confirm it only if it is still accurate.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle_outline, size: 17),
                      label: const Text('Still accurate'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: isDark ? AppThemes.darkSubtitleColor : Colors.black38,
            splashRadius: 16,
            tooltip: 'Remove this fact',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.confidence, required this.isDark});

  final double confidence;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color =
        confidence >= 0.8
            ? Colors.green[400]!
            : confidence >= 0.5
            ? Colors.orange[400]!
            : Colors.red[300]!;

    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(confidence * 100).round()}% confidence',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppThemes.darkSubtitleColor : Colors.black38,
          ),
        ),
      ],
    );
  }
}
