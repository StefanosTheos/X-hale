import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/settings_pages/about_us.dart';
import 'package:smoking/pages/settings_pages/faqs.dart';
import 'package:smoking/pages/settings_pages/more_help.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/providers/user_message_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/themes.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final status = await Permission.notification.status;
      final userState = ref.read(userProvider);
      final userNotifier = ref.read(userProvider.notifier);

      if (status.isGranted && !userState.notifications) {
        await userNotifier.toggleNotifications(true);
      }
    }
  }

  /// Apply a new notifications-enabled value, handling the three permission
  /// states (granted / denied / permanently-denied). Shared between the
  /// "Allow Notifications" card's tap action and its trailing `Switch`'s
  /// `onChanged` — previously those two callbacks held ~40 lines of
  /// byte-for-byte identical permission-flow code.
  Future<void> _handleNotificationToggle(bool target) async {
    final userNotifier = ref.read(userProvider.notifier);
    final status = await Permission.notification.status;

    if (status.isGranted) {
      await userNotifier.toggleNotifications(target);
      return;
    }

    if (status.isDenied) {
      final newStatus = await Permission.notification.request();
      if (newStatus.isGranted) {
        await userNotifier.toggleNotifications(true);
      } else {
        _showEnableInSettingsSnackBar();
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      _showEnableInSettingsSnackBar();
      await openAppSettings();
    }
  }

  void _showEnableInSettingsSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enable notifications from system settings.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final isDark = ref.isDark;

    final backgroundGradient =
        isDark ? AppThemes.darkGradient : AppThemes.lightGradient;
    final dialogGradient =
        isDark ? AppThemes.darkDialogGradient : AppThemes.lightDialogGradient;
    final cardColor =
        isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor;
    final textColor =
        isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;
    final subtitleColor =
        isDark ? AppThemes.darkSubtitleColor : AppThemes.lightSubtitleColor;
    final iconColor =
        isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor;

    Widget buildSettingsCard(
      String title, {
      required String subtitle,
      required VoidCallback onTap,
      Widget? trailing,
    }) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 10),
        color: cardColor,
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
          trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: iconColor),
          onTap: onTap,
        ),
      );
    }

    void showThemeDialog() {
      showDialog(
        context: context,
        builder:
            (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: dialogGradient,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Theme',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RadioGroup<String>(
                      groupValue: userState.theme,
                      onChanged: (String? value) {
                        if (value != null) {
                          userNotifier.updateTheme(value);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Column(
                        children:
                            ['light', 'dark'].map((theme) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? const Color(0xFF2A2A2D)
                                            : const Color(0xffcaf0f8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      theme == 'light' ? 'Light' : 'Dark',
                                      style: TextStyle(color: textColor),
                                    ),
                                    value: theme,
                                    fillColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (states) =>
                                              states.contains(
                                                    WidgetState.selected,
                                                  )
                                                  ? const Color(0xFF0A84FF)
                                                  : null,
                                        ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF444444) : Colors.grey[300],
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
      );
    }

    return Scaffold(
      appBar: const BackAppBar(title: 'Settings'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        buildSettingsCard(
                          'Allow Notifications',
                          subtitle:
                              userState.notifications ? 'Enabled' : 'Disabled',
                          onTap: () => _handleNotificationToggle(
                            !userState.notifications,
                          ),
                          trailing: Switch(
                            value: userState.notifications,
                            activeThumbColor: const Color(0xFF0A84FF),
                            onChanged: _handleNotificationToggle,
                          ),
                        ),

                        buildSettingsCard(
                          'Change Color Theme',
                          subtitle:
                              'Active: ${userState.theme == 'light' ? 'Light' : 'Dark'}',
                          onTap: showThemeDialog,
                        ),
                        buildSettingsCard(
                          'Contact Us',
                          subtitle: 'Send us a message',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) {
                                String message = '';
                                final isDark = ref.isDark;
                                final textColor =
                                    isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;
                                final counterColor =
                                    isDark ? Colors.grey[300] : Colors.black;
                                final dialogGradient = LinearGradient(
                                  colors:
                                      isDark
                                          ? [
                                            const Color(0xFF2A2A2D),
                                            const Color(0xFF3A3A3E),
                                          ]
                                          : [
                                            const Color(0xffcaf0f8),
                                            const Color(0xffade8f4),
                                          ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                );

                                return StatefulBuilder(
                                  builder: (context, setInnerState) {
                                    return Consumer(
                                      builder: (context, ref, _) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.7,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: dialogGradient,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(20),
                                                  ),
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Send a message',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Container(
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: textColor,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: TextField(
                                                      maxLength: 400,
                                                      // Hard-truncate at the
                                                      // cap — without this,
                                                      // pasting (or some IME
                                                      // composing flows) can
                                                      // produce a string
                                                      // longer than 400 chars
                                                      // even though the
                                                      // counter says 400/400.
                                                      maxLengthEnforcement:
                                                          MaxLengthEnforcement
                                                              .enforced,
                                                      maxLines: null,
                                                      expands: true,
                                                      style: TextStyle(
                                                        color: textColor,
                                                      ),
                                                      cursorColor: textColor,
                                                      textAlignVertical:
                                                          TextAlignVertical.top,
                                                      onChanged: (value) {
                                                        setInnerState(
                                                          () => message = value,
                                                        );
                                                      },
                                                      decoration: InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText:
                                                            'Type your message here...',
                                                        hintStyle: TextStyle(
                                                          color: textColor
                                                              .withAlpha(
                                                                (0.6 * 255)
                                                                    .round(),
                                                              ),
                                                        ),
                                                        counterText: '',
                                                        contentPadding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      '${message.length}/400',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        // Tint red within ~10% of the 400-char cap so
                                                        // the user gets a visible warning before
                                                        // hitting the hard limit. Bold at the cap.
                                                        fontWeight: message.length >= 400
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: message.length >= 360
                                                            ? Colors.redAccent
                                                            : counterColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              isDark
                                                                  ? const Color(
                                                                    0xFF444444,
                                                                  )
                                                                  : Colors
                                                                      .grey[300],
                                                          foregroundColor:
                                                              textColor,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed:
                                                            // Defense-in-depth
                                                            // against the
                                                            // `maxLength`
                                                            // bypass cited
                                                            // above: refuse to
                                                            // send anything
                                                            // over the cap
                                                            // even if the
                                                            // field somehow
                                                            // accepted it.
                                                            message
                                                                        .trim()
                                                                        .isEmpty ||
                                                                    message.length >
                                                                        400
                                                                ? null
                                                                : () async {
                                                                  try {
                                                                    final userId =
                                                                        userState
                                                                            .userId;
                                                                    await ref
                                                                        .read(
                                                                          messageControllerProvider
                                                                              .notifier,
                                                                        )
                                                                        .sendMessage(
                                                                          userId:
                                                                              userId,
                                                                          message:
                                                                              message,
                                                                        );
                                                                    if (context
                                                                        .mounted) {
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text(
                                                                            'Message sent successfully!',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  } catch (e) {
                                                                    if (context
                                                                        .mounted) {
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            'Error: ${e.toString()}',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              isDark
                                                                  ? AppThemes
                                                                      .darkCloseButtonColor
                                                                  : AppThemes
                                                                      .lightCloseButtonColor,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Send',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        buildSettingsCard(
                          'About Us',
                          subtitle: 'Learn more about the team',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutUsPage(),
                              ),
                            );
                          },
                        ),
                        buildSettingsCard(
                          'FAQs',
                          subtitle: 'Common questions answered',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FAQsPage(),
                              ),
                            );
                          },
                        ),
                        buildSettingsCard(
                          'I need more help',
                          subtitle: 'Seek help from a professional',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
