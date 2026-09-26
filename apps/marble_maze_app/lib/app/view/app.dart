import 'package:level_presentation/level_presentation.dart';
import 'package:marble_maze_app/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget of the app.
class App extends StatelessWidget {
  /// Creates the app around [boardView], the level play screen's 3D view.
  const new({required this.boardView, super.key});

  /// The board and marble view. Tests replace it because Flutter GPU does
  /// not render in widget tests.
  final Widget boardView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LevelPlayView(boardView: boardView),
    );
  }
}
