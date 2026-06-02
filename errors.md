## Unresolved errors

- [ ] **#22 — `2048` has no pause / no resume affordance.**
  `lib/mini_games/2048/home2048.dart` — both Snake (`game_page.dart:181-210`, play/pause FAB) and Flappy (`menus/game_intro.dart` + `game_over.dart`) have an explicit pause path. 2048 only has a reset button (line 278-285). For a session-style game where users may put the phone down mid-board, this is inconsistent UX.
  **Fix:** Add a pause FAB that flips a `bool _isPaused`; `handleGesture` early-returns when paused.

- [ ] **#29 — `HealthBenefitsState` is hand-written; every other state model uses `@freezed`.**
  `lib/models/healthbenefits_state.dart:3-60` — manual `copyWith` (lines 30-40), manual `toAppwrite` / `fromAppwrite`. The codebase has nine `*.freezed.dart` files for the other state classes. The hand-written copyWith is error-prone — every new field needs a manual entry, and there's no compile-time guard that all fields are wired.
  **Fix:** Annotate with `@freezed`, regenerate via `dart run build_runner build --delete-conflicting-outputs`. Keep `hasAchieved`, `timeSinceQuit`, `calculateProgress`, `completionDateFor` as Freezed methods.

- [ ] **#40 — `ObstacleGenerator.generateObstacle` allocates `Random()` twice per spawn.**
  `lib/mini_games/flappy_bird/player/obstacle_generator.dart:70, 86` — line 70: `Random().nextDouble() * 100` and line 86: `Random().nextInt(...)` each instantiate a fresh `Random`. The 2048 code already adopted the single-static pattern (`grid.dart:6`). Flappy spawns a pair on every screen-crossing tick and re-seeds the generator each time.
  **Fix:** Add `final Random _rng = Random();` at class level and reuse it.

- [ ] **#43 — `tic_tac_toe::autoPlay` allocates `Random()` on every AI turn.**
  `lib/mini_games/tic_tac_toe/ttt_homepage.dart:109` — `empty[Random().nextInt(empty.length)]`. Called every 400 ms during single-player; same anti-pattern as #40.
  **Fix:** Add `final Random _random = Random();` to `TicHomePageState` and reuse it.

- [ ] **#48 — `UserState.initial()` uses `.toUtc()` for `quitDate`; the fromAppwrite empty-doc fallback uses `.toLocal()`.**
  `lib/models/user_state.dart:60` vs `lib/models/user_state.dart:73` — the two "default-ish" initial states label the same moment with different timezone flags. Downstream code that compares quitDates papers over this, but it is a footgun for future code that doesn't.
  **Fix:** Align both factory paths to `.toUtc()` (already the Appwrite-side convention).

- [ ] **#321 — `splash_page.dart` particle painter mutates state inside `paint`; `shouldRepaint => true`. (verify)**
  `lib/pages/starting_pages/splash_page.dart:102-105, 326-327` — `ParticlePainter.paint` calls `p.update(progress)` (mutates particle state) and `shouldRepaint` is unconditionally `true`. The `progress` parameter is ignored — animation speed is time-step-independent. Painter is non-idempotent.
  **Fix:** Drive motion from elapsed seconds (`controller.lastElapsedDuration`); compute new state in `addListener` and read-only inside `paint`.

- [ ] **#330 — `friends_main.dart` remove-friend has no haptic / undoable snackbar.**
  `lib/pages/home_pages/friends_main.dart:422-456` — destructive (wipes message history per dialog body) with no undo and no haptic.
  **Fix:** `HapticFeedback.mediumImpact()` before the destructive call; offer an Undo action on the success snackbar.

- [ ] **#356 — `edit_challenge.dart` Type dropdown is decorative (`onChanged: null`).**
  `lib/pages/home_pages/edit_challenge.dart:358-390` — Physical/Financial dropdown is disabled because type isn't editable post-creation. Showing it as a greyed dropdown rather than a read-only label is misleading.
  **Fix:** Replace with a read-only `Text("Type: Physical")`.

- [ ] **#360 — `dm.dart` filter re-allocates the messages list on every `friendProvider.messages` change. (verify)**
  `lib/pages/home_pages/dm.dart:98-105` — `.select((s) => s.messages)` narrows to the whole messages list. Any inbound DM (even for other chats) triggers a full filter + `toList`.
  **Fix:** Expose `messagesWith(otherUserId)` as a `family` provider that computes the filtered list inside the notifier.

- [ ] **#36 — Avatar picker has three nested dialogs.** (`account.dart:70-150`)

- [ ] **#41 — Mini-game cards have no loading indication for the game itself.** (snake / 2048 / tic-tac-toe)

- [ ] **#42 — Settings page theme switch doesn't preview.**

- [ ] **#55 — `test/` directory is still empty.**

- [ ] **#416 — All four mini-games re-implement their own "game over" overlay.**
  `lib/mini_games/snake/game_over.dart`, `flappy_bird/menus/game_over.dart`, `tic_tac_toe/ttt_homepage.dart:127-199`, `2048/home2048.dart:243-272` — each duplicates the gradient + "Score / High Score / Play Again" scaffold with different colors.
  **Fix:** Extract `MiniGameOverDialog({score, highScore, accentColor, onRetry, onHome})` in `pages/utils/dialogs.dart`.

- [ ] **#428 — `GameState` enum uses `SCREAMING_SNAKE_CASE` with a lint-ignore.**
  `lib/mini_games/flappy_bird/flappy_dash_game.dart:17-18` — `enum GameState { GAME_STARTED, GAME_OVER, GAME_LAUNCH, GAME_PAUSE }`. Matches no other enum in the codebase.
  **Fix:** Rename to `gameStarted`, `gameOver`, `gameLaunch`, `gamePause`; drop the `ignore` directive.

- [ ] **#429 — Flappy mini-game uses `Get` (GetX) for state, conflicting with Riverpod elsewhere. (verify scope)**
  `lib/mini_games/flappy_bird/dash_game_controller.dart`, `dash.dart:12`, `obstacle_generator.dart:13`, `flappy_dash_game.dart:7, 25`, `menus/game_intro.dart:19`, `menus/game_over.dart:23`, `menus/game_score.dart:17`. `Get.put`/`Get.find` is a global singleton that survives navigation (re-entering the game reuses stale state).
  **Fix:** Migrate `DashGameController` to a Riverpod `StateNotifier`/`Notifier`; drop the `get` dependency.

- [ ] **#430 — `ObstacleGenerator.intervalBetweenNextObstacle` is named like a time but used as a speed.**
  `lib/mini_games/flappy_bird/player/obstacle_generator.dart:15, 36` — `obstacle.x -= intervalBetweenNextObstacle * dt;` — units are px/s, not an interval.
  **Fix:** Rename to `obstacleSpeed` (or `scrollSpeed`).

---

## Rag_backend errors




---

## Already verified false positives

These showed up in prior sweeps but are actually fine — recording so they don't get re-flagged:

- `StateNotifier.mounted` IS exposed by the `state_notifier` package used here. `if (!mounted) return` guards inside notifiers are correct.
- `lib/pages/utils/dialogs.dart` and `lib/pages/utils/empty_state.dart` are already shared utilities — don't recreate them.
- `.flutter-plugins-dependencies` is already in `.gitignore`.
- "Several providers construct fresh `Databases`/HTTP objects per call site" was wrong: the only `Client()`/`Databases(...)` construction in `lib/` lives in `services/appwrite_providers.dart` (the canonical factory). `friends_provider.dart` receives `_db` through `ref.watch(databasesProvider)` at line 13; `notification_service.dart` has no Appwrite imports at all.
- "Delete all milestones has no confirmation" was wrong: both call sites in `account.dart` (lines 543, 599) only run downstream of `showRelapseConfirmDialog` and `showQuitDateChangeConfirmDialog` respectively. The destructive action is always behind a user-confirmed Yes/No prompt — it's just not literally titled "delete milestones".
- "`_lastLoadedAt` plumbing isn't reset on logout" was wrong: both `diaryProvider` and `forumPostProvider` watch `userProvider.select((u) => u.userId)`. A userId change tears down the entire notifier instance, taking `_lastLoadedAt` / `_hasMore` / `state` with it. (Note: this is *not* true for `friendProvider` and `progressProvider` — see #225 and #249.)
- "Several `debugPrint` calls log full state objects" was wrong: grep over `lib/providers/` shows zero dumps of state objects. Most prints are `'Error xyz: $e'` (single line). The only verbose call is `milestone_provider.dart:102` which adds a stack trace — diagnostic value, not noise.
- "`progress_provider` 1 Hz timer fires `state = state` redundantly" was wrong: `timeSinceQuit` advances by one second each tick, so the new state is genuinely different. The `cigsChanged` check is only a side-effect gate, not a state-set gate.
- "`diary.dart::_getColor` is unused" was wrong: it's referenced at `diary.dart:711, 721, 757, 764` to color the diary-entry cards from the stored hex.
- "`ChallengeNotifier.refresh` is a passthrough to `fetchChallenges`" was technically correct but the explicit method is the documented public entry point for pull-to-refresh; keep for callsite stability.
- "`progress_provider._isForeground` guard is redundant" was wrong: `_startTimer` keys off the field to refuse to start while backgrounded; the lifecycle hook is the only writer. Both reads are necessary.
- "Standardise on `State.mounted` over `context.mounted` in `account.dart`" was the wrong direction: modern Flutter's `use_build_context_synchronously` lint expects `context.mounted` when the `BuildContext` is used after the `await`. The file is now consistent on `context.mounted` throughout.
- "Per-page `_showErrorDialog` wrappers around `showAppErrorDialog` are dead re-exports" was wrong: the wrappers in `auth.dart` and `change_account_info.dart` are load-bearing for the `use_build_context_synchronously` lint. An instance-method call captures `this.context` synchronously even when invoked after an `await`; inlining `showAppErrorDialog(context, ...)` at every call site triggers the lint at all ~15 call sites. Keep the wrappers — `showAppErrorDialog` already handles the `context.mounted` check internally.
- "Splash screen is too long at 6.5s" was wrong: the duration is deliberate (brand-message cycle is a UX choice). Don't shorten it.
- "`_SparkleRingPainter` reuses one `Paint` object inside the loop" (`progress_provider.dart:368, 384`) is intentional — only the color mutates per iteration; the rest of the paint setup is constant. Re-allocating Paint per dot would be slower.
