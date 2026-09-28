import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:level_presentation/bubble_level/cubit/bubble_level_cubit.dart';
import 'package:level_presentation/bubble_level/view/bubble_level_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// The bubble level screen's module: wires a [BubbleLevelCubit] to the
/// [ITiltRepository] from context.
class BubbleLevelModule extends StatelessWidget {
  /// Creates a bubble level module.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BubbleLevelCubit(tiltRepository: context.read<ITiltRepository>()),
      child: const BubbleLevelView(),
    );
  }
}
