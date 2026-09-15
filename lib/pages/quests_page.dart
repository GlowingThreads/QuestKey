import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/quest_list.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  /// `null` means "All".
  QuestStatus? _filter = QuestStatus.inProgress;

  static const List<({QuestStatus? status, String asset, String label})>
  _filters = [
    (status: QuestStatus.inProgress, asset: Art.todo, label: 'ACTIVE'),
    (status: null, asset: Art.all, label: 'ALL'),
    (status: QuestStatus.completed, asset: Art.finished, label: 'DONE'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestListProvider>();
    final total = provider.quests.length;
    final done = provider.completedQuests.length;
    final completion = total == 0 ? 0.0 : done / total;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<AppState>().setIndex(2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.bronzeLight, width: 1.3),
        ),
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: Text(
          'NEW QUEST',
          style: AppFonts.label(size: 11, color: AppColors.gold),
        ),
      ),
      body: PageBackground(
        asset: Art.questsBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      const PortholeBadge(asset: Art.questLog, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quest Log',
                              style: AppFonts.heading(size: 22),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: AnimatedBar(
                                    fraction: completion,
                                    height: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$done / $total',
                                  style: AppFonts.body(
                                    size: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _FilterBar(
                    filters: _filters,
                    selected: _filter,
                    countFor:
                        (status) => provider.getFilteredQuests(status).length,
                    onSelected: (status) => setState(() => _filter = status),
                  ),
                ),
                const SizedBox(height: AppPadding.sm),
                Expanded(
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      child: QuestList(
                        key: ValueKey(_filter),
                        filterStatus: _filter,
                        expand: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 92),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three porthole seals; the chosen one lifts and glows.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final List<({QuestStatus? status, String asset, String label})> filters;
  final QuestStatus? selected;
  final int Function(QuestStatus?) countFor;
  final ValueChanged<QuestStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in filters)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(filter.status),
              child: AnimatedContainer(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      filter.status == selected
                          ? AppColors.amethyst.withValues(alpha: 0.55)
                          : AppColors.obsidian.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        filter.status == selected
                            ? AppColors.teal
                            : AppColors.bronze,
                    width: filter.status == selected ? 1.6 : 1,
                  ),
                  boxShadow:
                      filter.status == selected
                          ? [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: filter.status == selected ? 1.08 : 0.92,
                      duration: AppDurations.medium,
                      child: Opacity(
                        opacity: filter.status == selected ? 1 : 0.7,
                        child: Image.asset(
                          filter.asset,
                          width: 48,
                          height: 48,
                          errorBuilder:
                              (_, _, _) =>
                                  const Icon(Icons.circle_outlined, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filter.label} · ${countFor(filter.status)}',
                      style: AppFonts.label(
                        size: 9,
                        color:
                            filter.status == selected
                                ? AppColors.gold
                                : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
