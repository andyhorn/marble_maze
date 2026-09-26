import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Shown when the level select cubit fails to load the manifest.
class LevelSelectErrorView extends StatelessWidget {
  /// Creates a level select error view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.levelSelectTitle)),
      body: Center(child: Text(context.l10n.levelSelectErrorMessage)),
    );
  }
}
