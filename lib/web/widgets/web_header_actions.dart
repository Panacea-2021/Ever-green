import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model for a single header action button.
class WebHeaderAction {
  const WebHeaderAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Primary actions get the green gradient; secondary get outlined style.
  final bool isPrimary;
}

/// Notifier that holds the current page's header actions.
/// Pages can register their actions and the header will display them.
class WebHeaderActionsNotifier extends ChangeNotifier {
  List<WebHeaderAction> _actions = const [];
  String? _pageKey;

  List<WebHeaderAction> get actions => _actions;
  String? get pageKey => _pageKey;

  void setActions(List<WebHeaderAction> actions, {String? pageKey}) {
    _actions = actions;
    _pageKey = pageKey;
    notifyListeners();
  }

  /// Clears header actions. When called from route changes (no pageKey),
  /// always clears. When called from a specific page disposal (with pageKey),
  /// only clears if it matches the current page.
  void clearActions({String? pageKey}) {
    // Always clear when no pageKey specified (route change)
    // Only skip if a specific pageKey is given AND it doesn't match
    if (pageKey != null && _pageKey != pageKey) {
      return;
    }
    _actions = const [];
    _pageKey = null;
    notifyListeners();
  }
}

/// Global provider for header actions.
final webHeaderActionsProvider =
    ChangeNotifierProvider<WebHeaderActionsNotifier>((ref) {
  return WebHeaderActionsNotifier();
});

/// Mixin for screens that want to provide header actions on web.
/// Call [setHeaderActions] in build to register actions.
mixin WebHeaderActionsMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  String get _pageKey => '${widget.runtimeType}_$hashCode';

  /// Notifier cached while the page is mounted. `dispose()` may not touch
  /// `ref` (Riverpod forbids it once the element is disposed), so the
  /// reference is captured here instead.
  WebHeaderActionsNotifier? _cachedNotifier;

  /// Sets the header actions for this page. Call this when the page is built.
  /// Actions are set synchronously - if called during build, they will be
  /// visible immediately.
  void setHeaderActions(List<WebHeaderAction> actions) {
    // Schedule the action update for after the current build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(webHeaderActionsProvider);
        _cachedNotifier = notifier;
        notifier.setActions(actions, pageKey: _pageKey);
      }
    });
  }

  @override
  void dispose() {
    // Clear actions when the page is disposed, but only if we're still
    // the active page (pageKey matches). Uses the cached notifier because
    // `ref` cannot be read after the widget is disposed.
    final notifier = _cachedNotifier;
    final key = _pageKey;
    if (notifier != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.clearActions(pageKey: key);
      });
    }
    super.dispose();
  }
}

/// Widget that builds header action buttons with consistent styling.
class WebHeaderActionButtons extends StatelessWidget {
  const WebHeaderActionButtons({super.key, required this.actions});

  final List<WebHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _buildActionButton(actions[i]),
        ],
      ],
    );
  }

  Widget _buildActionButton(WebHeaderAction action) {
    if (action.isPrimary) {
      return _PrimaryActionButton(action: action);
    }
    return _SecondaryActionButton(action: action);
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({required this.action});

  final WebHeaderAction action;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.action.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hover
                  ? [const Color(0xFF15A332), const Color(0xFF128026)]
                  : [const Color(0xFF138A2A), const Color(0xFF106220)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF106220).withValues(alpha: _hover ? 0.25 : 0.18),
                blurRadius: _hover ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.action.icon != null) ...[
                Icon(widget.action.icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.action.label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatefulWidget {
  const _SecondaryActionButton({required this.action});

  final WebHeaderAction action;

  @override
  State<_SecondaryActionButton> createState() => _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<_SecondaryActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.action.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFE8F5E9) : const Color(0xFFF3F8F4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? const Color(0xFFB0D4B5) : const Color(0xFFD4E3D6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.action.icon != null) ...[
                Icon(
                  widget.action.icon,
                  size: 18,
                  color: const Color(0xFF0E501B),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.action.label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0E501B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
