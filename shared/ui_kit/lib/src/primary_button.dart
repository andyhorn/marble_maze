import 'package:material_ui/material_ui.dart';

/// The app's primary call-to-action button.
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button. [onPressed] runs when tapped.
  const new({required this.onPressed, required this.child, super.key});

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The button's label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: child);
  }
}
