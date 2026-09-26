import 'package:level_presentation/level_select/cubit/level_list_entry.dart';
import 'package:localizations/localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// A single row in the level select list: [entry]'s title, best time (or a
/// "no best time" message), and par status. Tapping the row calls [onTap].
class LevelListItem extends StatelessWidget {
  /// Creates a level list item for [entry].
  const new({required this.entry, required this.onTap, super.key});

  /// The level this row represents.
  final LevelListEntry entry;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bestTime = entry.bestTime;
    final bestTimeText = bestTime == null
        ? l10n.levelSelectNoBestTime
        : l10n.levelSelectBestTimeLabel(formatDuration(bestTime));

    return ListTile(
      title: Text(entry.title),
      subtitle: Text('$bestTimeText\n${_parStatusText(l10n, entry)}'),
      isThreeLine: true,
      onTap: onTap,
    );
  }

  String _parStatusText(AppLocalizations l10n, LevelListEntry entry) {
    final par = entry.par;
    if (par == null) return l10n.levelSelectParNone;

    final bestTime = entry.bestTime;
    final beatsPar = bestTime != null && bestTime <= par;
    return beatsPar ? l10n.levelSelectParBeaten : l10n.levelSelectParNotBeaten;
  }
}
