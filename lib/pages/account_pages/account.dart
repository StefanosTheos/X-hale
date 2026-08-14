import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smoking/pages/account_pages/account_dialogs.dart';
import 'package:smoking/pages/account_pages/change_account_info.dart';
import 'package:smoking/pages/account_pages/change_smoking_preferences.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/account_pages/widgets/avatar_display.dart';
import 'package:smoking/pages/account_pages/widgets/settings_card.dart';
import 'package:smoking/pages/starting_pages/auth.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/healthbenefits_provider.dart';
import 'package:smoking/providers/milestone_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/chat_service.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key, required this.account});
  final Account account;

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final DateTime placeholderBirthDate = DateTime(2000, 1, 1);
  final ImagePicker _picker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    // Narrowed selects: this page only renders five fields off `userState`,
    // but the 1 Hz `progressProvider` tick mutates other userState fields
    // (counts, sync timestamps) every second. Watching the whole object
    // rebuilt the entire ~370-line subtree every tick.
    final userId = ref.watch(userProvider.select((u) => u.userId));
    final name = ref.watch(userProvider.select((u) => u.name));
    final avatarPath = ref.watch(userProvider.select((u) => u.avatarPath));
    final achievementsCount = ref.watch(
      userProvider.select((u) => u.achievementsCount),
    );
    final quitDate = ref.watch(userProvider.select((u) => u.quitDate));
    final userNotifier = ref.read(userProvider.notifier);
    final isDark = ref.isDark;
    Future<void> deleteAllMilestones() async {
      try {
        // Tactile signal for a destructive action — confirmation dialog has
        // already been shown upstream, so this fires after the user
        // committed. Mirrors the positive haptic in `_ChallengeCompletionDialog`.
        HapticFeedback.mediumImpact();
        final milestoneNotifier = ref.read(milestoneProvider.notifier);
        await milestoneNotifier.deleteAllMilestones(userId);
        // No success snackbar here on purpose. Every caller (relapse,
        // edit quit date) already shows its own composite "Progress
        // restarted - milestones cleared" / "Quit date updated -
        // milestones cleared" snackbar; surfacing a separate "All
        // milestones cleared successfully" toast queued two snackbars
        // back-to-back for one user action.
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear milestones')),
          );
        }
        if (kDebugMode) debugPrint('Error deleting milestones: $e');
      }
    }

    Future<void> pickImageFromGallery() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && context.mounted) {
        try {
          await userNotifier.updateAvatarFromFile(image.path);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update avatar: $e')),
            );
          }
        }
      }
    }

    Future<void> showAvatarPicker() async {
      final pick = await showSelectAvatarDialog(context);
      if (pick != null) {
        await userNotifier.updateAvatar(pick);
      }
    }

    Future<void> showImageSourceOptions() async {
      final source = await showImageSourceDialog(context, isDark);
      if (source == AvatarSource.gallery) {
        await pickImageFromGallery();
      } else if (source == AvatarSource.preset) {
        await showAvatarPicker();
      }
    }

    Future<void> showProfilePicOptions() async {
      final ok = await showProfilePicChangeConfirmDialog(context, isDark);
      if (ok) await showImageSourceOptions();
    }

    Future<void> editUsername() async {
      final result = await showEditUsernameDialog(
        context: context,
        isDark: isDark,
        initialValue: name,
        validate: (candidate) async {
          if (candidate.isEmpty) return 'Username cannot be empty';
          final exists = await userNotifier.checkIfUsernameExists(candidate);
          if (exists && candidate != name) {
            return 'This username already exists';
          }
          return null;
        },
      );
      if (result != null && result.isNotEmpty && context.mounted) {
        await userNotifier.updateName(result);
      }
    }

    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        title: Text(
          'Account Settings',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
        ),
        child: SafeArea(
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AvatarDisplay(
                          avatarPath: avatarPath,
                          onTap: showProfilePicOptions,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$achievementsCount',
                              style: TextStyle(
                                fontSize: 20,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/icons/trophies.png',
                              height: 18,
                              width: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: editUsername,
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                              color:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SettingsCard(
                          title: 'Relapse',
                          subtitle:
                              'Current Quit Date: ${formatDate(quitDate.toLocal())}',
                          onTap: () async {
                            final confirmed = await showRelapseConfirmDialog(
                              context,
                              isDark,
                            );
                            if (!confirmed) return;
                            final newQuitDate = DateTime.now().toLocal();
                            await userNotifier.updatequitDate(newQuitDate);
                            try {
                              final jwt =
                                  (await widget.account.createJWT()).jwt;
                              await ChatService.recordRelapse(
                                jwt: jwt,
                                occurredAt: newQuitDate,
                              );
                            } catch (e) {
                              // Progress reset remains authoritative even if the
                              // optional chatbot support marker cannot be stored.
                              if (kDebugMode) {
                                debugPrint('Relapse support marker failed: $e');
                              }
                            }
                            await deleteAllMilestones();
                            final milestoneNotifier = ref.read(
                              milestoneProvider.notifier,
                            );
                            await milestoneNotifier
                                .reinitializeWithNewStartDate(newQuitDate);
                            await ref
                                .read(healthBenefitsProvider.notifier)
                                .resetBenefits(newQuitDate);
                            // Awaited so the subsequent `reloadUser` sees
                            // the final `numHealthBenefit` count. Without
                            // the await, `reloadUser` could read the
                            // intermediate value `resetBenefits` just wrote
                            // (0) before `checkAchievements` finishes
                            // writing the real count back, leaving the
                            // local userState — and the achievements
                            // counter on this page — stale until something
                            // else refreshes it.
                            await ref
                                .read(healthBenefitsProvider.notifier)
                                .checkAchievements();
                            await userNotifier.reloadUser();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Progress restarted - milestones cleared',
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        SettingsCard(
                          title: 'Edit Smoking Preferences',
                          subtitle: 'Update type and frequency',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SmokingPreferencesPage(userId: userId),
                              ),
                            );
                          },
                        ),
                        SettingsCard(
                          title: 'Edit Quit Date',
                          subtitle: 'Change your quit date',
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: quitDate.toLocal(),
                              firstDate: placeholderBirthDate,
                              lastDate: DateTime.now().toLocal(),
                            );
                            if (pickedDate == null || !context.mounted) return;
                            final confirmed =
                                await showQuitDateChangeConfirmDialog(
                                  context,
                                  isDark,
                                );
                            if (!confirmed) return;
                            await userNotifier.updatequitDate(pickedDate);
                            await deleteAllMilestones();
                            final milestoneNotifier = ref.read(
                              milestoneProvider.notifier,
                            );
                            await milestoneNotifier
                                .reinitializeWithNewStartDate(pickedDate);
                            await ref
                                .read(healthBenefitsProvider.notifier)
                                .resetBenefits(pickedDate);
                            // See the relapse handler above — without
                            // awaiting `checkAchievements`, `reloadUser`
                            // can read the `numHealthBenefit` value
                            // `resetBenefits` just wrote (0) before the
                            // checker finishes re-adding the benefits
                            // that the new quit date already entitles
                            // the user to. The account-page achievements
                            // counter would then stay stale until the
                            // user opened the achievements page.
                            await ref
                                .read(healthBenefitsProvider.notifier)
                                .checkAchievements();
                            await userNotifier.reloadUser();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Quit date updated - milestones cleared',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        SettingsCard(
                          title: 'Edit Account Information',
                          subtitle: 'Update email, password or number',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChangeAccountInfoPage(
                                      account: widget.account,
                                    ),
                              ),
                            );
                          },
                        ),
                        SettingsCard(
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          onTap: () async {
                            final confirmed = await showLogoutConfirmDialog(
                              context,
                              isDark,
                            );
                            if (!confirmed) return;
                            // Drop the push target BEFORE the session — once
                            // the session is gone we no longer have auth to
                            // touch it, and the row would linger on Appwrite.
                            try {
                              await widget.account.deletePushTarget(
                                targetId: 'push_$userId',
                              );
                            } on AppwriteException catch (e) {
                              // 404 = already gone, fine. Anything else: log
                              // and keep going so a broken push target can't
                              // block the user from signing out.
                              if (e.code != 404 && kDebugMode) {
                                debugPrint(
                                  'deletePushTarget on logout failed: $e',
                                );
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                debugPrint(
                                  'deletePushTarget on logout failed: $e',
                                );
                              }
                            }
                            try {
                              await widget.account.deleteSession(
                                sessionId: 'current',
                              );
                              if (!context.mounted) return;
                              // Navigate AWAY from the account page first.
                              // Then defer the local UserState reset (and
                              // FCM token cleanup) to after the next frame,
                              // when the account-page subtree has been
                              // unmounted and is no longer listening to
                              // `userProvider`. Previously `logout()` ran
                              // synchronously before the navigation, so
                              // the account page rebuilt with the zeroed
                              // initial state (0 achievements, default
                              // light theme) for one frame — visible as a
                              // flash before the route swap completed.
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AuthPage(account: widget.account),
                                ),
                                (route) => false,
                              );
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                userNotifier.logout();
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logout failed'),
                                  ),
                                );
                              }
                            }
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
