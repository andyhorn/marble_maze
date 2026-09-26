import 'package:material_ui/material_ui.dart';

/// A secondary, lower-emphasis button.
class SecondaryButton extends StatelessWidget {
  /// Creates a secondary button. [onPressed] runs when tapped.
  const new({required this.onPressed, required this.child, super.key});

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The button's label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}
