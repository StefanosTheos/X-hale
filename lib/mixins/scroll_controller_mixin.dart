import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixes a lazily-created [ScrollController] into a [ConsumerState] and
/// disposes it automatically. Replaces the field-plus-dispose pair that was
/// duplicated across `chatbot_page`, `diary`, `dm`, `forum`, and `home`.
mixin AutoDisposeScrollController<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  late final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
