import 'package:marble_maze_app/l10n/l10n.dart';
import 'package:marble_maze_app/scene_preview/scene_preview.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget of the app.
class App extends StatelessWidget {
  const new({super.key, this.sceneView = const CubeSceneView()});

  /// The 3D view shown on the preview page. Tests replace it because Flutter
  /// GPU does not render in widget tests.
  final Widget sceneView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScenePreviewPage(sceneView: sceneView),
    );
  }
}
