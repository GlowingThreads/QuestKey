import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
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

  static const List<({QuestStatus? status, IconData icon, String label})>
  _filters = [
    (
      status: QuestStatus.inProgress,
      icon: Icons.hourglass_top,
      label: 'Active',
    ),
    (status: null, icon: Icons.all_inclusive, label: 'All'),
    (status: QuestStatus.completed, icon: Icons.check_circle, label: 'Done'),
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
        backgroundColor: AppColors.accentPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New quest'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: PageBackground(
        asset: 'assets/images/app_assets/quests_bkg.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.xxl,
              AppPadding.lg,
              AppPadding.xxl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quest Log',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '$done / $total done',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: AnimatedBar(
                    fraction: completion,
                    height: 6,
                    colors: const [
                      AppColors.accentPurple,
                      AppColors.accentGreen,
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _FilterBar(
                    filters: _filters,
                    selected: _filter,
                    countFor:
                        (status) => provider.getFilteredQuests(status).length,
                    onSelected: (status) => setState(() => _filter = status),
                  ),
                ),
                const SizedBox(height: AppPadding.lg),
                Expanded(
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
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
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented filter with a sliding highlight and live counts.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final List<({QuestStatus? status, IconData icon, String label})> filters;
  final QuestStatus? selected;
  final int Function(QuestStatus?) countFor;
  final ValueChanged<QuestStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = filters.indexWhere((f) => f.status == selected);

    return GlassPanel(
      padding: const EdgeInsets.all(4),
      radius: AppRadius.lg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / filters.length;
          return SizedBox(
            height: 56,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AppDurations.medium,
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowPurple.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final filter in filters)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => onSelected(filter.status),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                filter.icon,
                                size: 18,
                                color:
                                    filter.status == selected
                                        ? AppColors.accentGold
                                        : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${filter.label} (${countFor(filter.status)})',
                                style: TextStyle(
                                  fontSize: AppFontSizes.xs,
                                  fontWeight:
                                      filter.status == selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      filter.status == selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
