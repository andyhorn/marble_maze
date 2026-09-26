import 'package:material_ui/material_ui.dart';

/// A translucent panel for HUD overlays drawn over the 3D board, such as the
/// "tap to start" and win screens.
class OverlayPanel extends StatelessWidget {
  /// Creates an overlay panel around [child].
  const new({required this.child, super.key});

  /// The panel's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
