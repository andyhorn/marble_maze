import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// Shown instead of the game's `App` when `buildApp` finds Flutter GPU (or
/// the physics backend) unavailable at startup, rather than crashing deeper
/// into the render path.
class UnsupportedDeviceApp extends StatelessWidget {
  /// Creates the unsupported-device app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: appTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const UnsupportedDeviceView(),
    );
  }
}

/// The unsupported-device message shown in place of the game.
class UnsupportedDeviceView extends StatelessWidget {
  /// Creates the unsupported-device view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.unsupportedDeviceTitle, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(l10n.unsupportedDeviceMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
