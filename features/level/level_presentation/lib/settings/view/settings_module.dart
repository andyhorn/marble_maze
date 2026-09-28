import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/settings/cubit/settings_cubit.dart';
import 'package:level_presentation/settings/view/settings_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:settings_domain/settings_domain.dart';

/// The settings screen's module: wires a [SettingsCubit] to the
/// [ISettingsRepository] from context.
class SettingsModule extends StatelessWidget {
  /// Creates a settings module. [onOpenBubbleLevel] is called when the
  /// bubble level row is tapped.
  const new({required this.onOpenBubbleLevel, super.key});

  /// Called when the player taps the bubble level row.
  final VoidCallback onOpenBubbleLevel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = SettingsCubit(
          settingsRepository: context.read<ISettingsRepository>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: SettingsView(onOpenBubbleLevel: onOpenBubbleLevel),
    );
  }
}
