import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Shown while the level select cubit loads the manifest and records.
class LevelSelectLoadingView extends StatelessWidget {
  /// Creates a level select loading view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.levelSelectTitle)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
