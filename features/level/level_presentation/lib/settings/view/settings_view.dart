import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/settings/cubit/settings_cubit.dart';
import 'package:level_presentation/settings/cubit/settings_state.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The settings screen: the tilt calibration toggle, and a row that opens
/// the bubble level.
class SettingsView extends StatelessWidget {
  /// Creates a settings view. [onOpenBubbleLevel] is called when the bubble
  /// level row is tapped.
  const new({required this.onOpenBubbleLevel, super.key});

  /// Called when the player taps the bubble level row.
  final VoidCallback onOpenBubbleLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsCalibrateTiltTitle),
              subtitle: Text(l10n.settingsCalibrateTiltSubtitle),
              value: state.calibrateTilt,
              onChanged: (value) =>
                  context.read<SettingsCubit>().setCalibrateTilt(value: value),
            ),
            SwitchListTile(
              title: Text(l10n.settingsShowBubbleLevelTitle),
              subtitle: Text(l10n.settingsShowBubbleLevelSubtitle),
              value: state.showBubbleLevel,
              onChanged: (value) => context
                  .read<SettingsCubit>()
                  .setShowBubbleLevel(value: value),
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: Text(l10n.settingsBubbleLevel),
              onTap: onOpenBubbleLevel,
            ),
          ],
        ),
      ),
    );
  }
}
