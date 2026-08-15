import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/pages/starting_pages/auth.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/chat_service.dart';

class HaileyDataPrivacyPage extends ConsumerStatefulWidget {
  const HaileyDataPrivacyPage({super.key});

  @override
  ConsumerState<HaileyDataPrivacyPage> createState() =>
      _HaileyDataPrivacyPageState();
}

class _HaileyDataPrivacyPageState extends ConsumerState<HaileyDataPrivacyPage> {
  String? _jwt;
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _refreshJwt();
  }

  Future<void> _refreshJwt() async {
    try {
      final account = ref.read(accountProvider);
      final jwtObj = await account.createJWT();
      if (mounted) setState(() => _jwt = jwtObj.jwt);
    } catch (e) {
      debugPrint('HaileyDataPrivacyPage: JWT error: $e');
    }
  }

  // ── Export ───────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    final jwt = _jwt;
    if (jwt == null) return;
    setState(() => _isExporting = true);
    try {
      final data = await ChatService.exportData(jwt: jwt);
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: pretty));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data copied to clipboard'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Delete all chatbot data ───────────────────────────────────────────────

  void _confirmDeleteAll() {
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
                    'Delete all chatbot data?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? AppThemes.darkTextColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This requests deletion of your Hailey conversation records and structured memory facts through two separate operations. Completed deletions cannot be undone; if either operation fails, the app reports an error and you can retry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppThemes.darkSubtitleColor : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAllChatbotData();
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
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteAllChatbotData() async {
    final jwt = _jwt;
    if (jwt == null) return;
    setState(() => _isDeleting = true);
    try {
      await Future.wait([
        ChatService.clearHistory(jwt: jwt),
        ChatService.clearAllMemory(jwt: jwt),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chatbot data deleted'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _confirmDeleteAccount() {
    final isDark = ref.read(userProvider.select((u) => u.theme == 'dark'));
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: isDark ? AppThemes.darkAppBarColor : Colors.white,
            title: const Text('Permanently delete account?'),
            content: const Text(
              'This permanently deletes your X-hale profile, progress, diary, '
              'challenges, social records, avatar, Hailey data, and sign-in account. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _deleteAccount();
                },
                child: const Text('Delete account'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    final jwt = _jwt;
    if (jwt == null) return;
    setState(() => _isDeletingAccount = true);
    try {
      await ChatService.deleteAccount(jwt: jwt);
      if (!mounted) return;
      final account = ref.read(accountProvider);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthPage(account: account)),
        (route) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userProvider.notifier).logout();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Account deletion failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;
    final textColor =
        isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;
    final subtitleColor =
        isDark ? AppThemes.darkSubtitleColor : AppThemes.lightSubtitleColor;
    final cardColor = isDark ? AppThemes.darkCardColor : Colors.white;
    final accentColor =
        isDark ? AppThemes.darkDiaryTextColor : const Color(0xFF0077B6);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: textColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Data & Privacy',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Privacy Policy ──────────────────────────────────────────
            _SectionHeader(
              label: 'Privacy Policy',
              icon: Icons.policy_outlined,
              color: accentColor,
            ),
            const SizedBox(height: 8),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: accentColor,
                collapsedIconColor: subtitleColor,
                title: Text(
                  'X-hale data-handling summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Current implementation: 2026-08-15',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                children: [
                  _PolicySection(
                    heading: 'Data handled by X-hale',
                    body:
                        '• Account credentials and sessions — handled by Appwrite authentication.\n'
                        '• Profile and cessation information — including quit date and smoking preferences.\n'
                        '• Application records — including progress, diary entries, motivations, challenges, achievements, social content, and notification-related records.\n'
                        '• Hailey records — conversation history and structured memory facts derived from conversations.\n\n'
                        'The biometrics demonstration contains static placeholder values and does not collect wearable measurements or send biometric data to Hailey.',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _PolicySection(
                    heading: 'How we use your data',
                    body:
                        '• To personalise Hailey\'s responses based on your quit history.\n'
                        '• To display your progress (days smoke-free, money saved, health benefits).\n'
                        '• To send optional push notifications if you enable them.\n\n'
                        'The implemented application does not contain an advertising or data-sale function.',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _PolicySection(
                    heading: 'Where your data is stored',
                    body:
                        'X-hale account, application, conversation, and memory records are stored in the configured Appwrite Cloud project. The Hailey service is hosted on Hugging Face Spaces.\n\n'
                        'To answer a message, Hailey may send relevant prompt context to Groq for language-model inference. Smoking-cessation questions may also be embedded through Cloudflare Workers AI, or locally when the configured fallback is active, and searched in Qdrant Cloud. Qdrant stores the curated knowledge vectors rather than your conversation history.\n\n'
                        'Transport, processing, logging, and retention by external providers are governed by their own configurations and policies; this screen does not promise that providers retain no request data.',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _PolicySection(
                    heading: 'Your rights',
                    body:
                        '• View active memory — review the active structured facts Hailey may use on the "Hailey\'s memory" screen.\n'
                        '• Delete individual facts — tap the delete icon next to any fact.\n'
                        '• Export Hailey data — copy your complete Hailey chat history and structured memory records to the clipboard as JSON. This is not an export of every X-hale application record.\n'
                        '• Delete chatbot data — request deletion of conversation history and structured memory facts using the control below.\n'
                        '• Delete your account — request deletion of your Appwrite identity and X-hale records controlled by the configured project.\n\n'
                        'For access, correction, portability, erasure, or other privacy requests beyond these in-app controls, use the contact address below.',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _PolicySection(
                    heading: 'Data retention',
                    body:
                        'The application does not promise a fixed erasure deadline or a universal provider-retention period. Appwrite application records remain until they are removed through an available deletion control or another authorized process. Account deletion removes records controlled by the configured Appwrite project and then the authentication identity. Data processed or retained independently by external providers remains subject to those providers\' policies and cannot be erased directly by this workflow.',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  _PolicySection(
                    heading: 'Contact',
                    body: 'For privacy-related requests: steventheos@gmail.com',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Your Data ───────────────────────────────────────────────
            _SectionHeader(
              label: 'Your data',
              icon: Icons.folder_outlined,
              color: accentColor,
            ),
            const SizedBox(height: 8),

            // Export
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.download_outlined,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Export my data',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Copy your chat history and memory to the clipboard as JSON.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                trailing:
                    _isExporting
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                        : Icon(Icons.chevron_right, color: subtitleColor),
                onTap: (_jwt == null || _isExporting) ? null : _exportData,
              ),
            ),

            const SizedBox(height: 10),

            // Delete all
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _isDeleting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                          : const Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                            size: 22,
                          ),
                ),
                title: Text(
                  'Delete all chatbot data',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.red[300] : Colors.red[700],
                  ),
                ),
                subtitle: Text(
                  'Request deletion of Hailey conversation records and structured memory facts.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                trailing: Icon(Icons.chevron_right, color: subtitleColor),
                onTap: (_jwt == null || _isDeleting) ? null : _confirmDeleteAll,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading:
                    _isDeletingAccount
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                        : const Icon(
                          Icons.person_remove_outlined,
                          color: Colors.red,
                          size: 22,
                        ),
                title: Text(
                  'Delete my X-hale account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.red[300] : Colors.red[700],
                  ),
                ),
                subtitle: Text(
                  'Request deletion of your account and records controlled by the configured Appwrite project.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                trailing: Icon(Icons.chevron_right, color: subtitleColor),
                onTap:
                    (_jwt == null || _isDeletingAccount)
                        ? null
                        : _confirmDeleteAccount,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.heading,
    required this.body,
    required this.textColor,
    this.subtitleColor,
  });

  final String heading;
  final String body;
  final Color textColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
