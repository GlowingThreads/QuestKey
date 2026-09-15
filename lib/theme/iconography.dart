/// Maps game concepts to icons and artwork so the UI never has to fall back
/// to emoji. Data models keep their emoji strings for backwards
/// compatibility; the widgets look things up here instead.
library;

import 'package:flutter/material.dart';
import 'package:quest_key/models/quest.dart';

/// Porthole badge artwork (each already contains its hand-lettered label).
class Art {
  Art._();

  static const String home = 'assets/images/app_assets/home.png';
  static const String questLog = 'assets/images/app_assets/quest_log.png';
  static const String create = 'assets/images/app_assets/create.png';
  static const String hero = 'assets/images/app_assets/hero.png';
  static const String info = 'assets/images/app_assets/info.png';
  static const String todo = 'assets/images/app_assets/todo.png';
  static const String all = 'assets/images/app_assets/all.png';
  static const String finished = 'assets/images/app_assets/finished.png';
  static const String progressBadge = 'assets/images/app_assets/progress.png';
  static const String completedBadge = 'assets/images/app_assets/completed.png';
  static const String levelUp = 'assets/images/app_assets/lvl_up.png';
  static const String appIcon = 'assets/images/app_assets/qk_icon.png';
  static const String orb = 'assets/images/app_assets/orb_bkg.png';

  static const String homeBackground = 'assets/images/app_assets/home_bkg.png';
  static const String questsBackground =
      'assets/images/app_assets/quests_bkg.png';
  static const String createBackground =
      'assets/images/app_assets/create_bkg.png';
  static const String heroBackground = 'assets/images/app_assets/hero_bkg.jpg';
  static const String infoBackground = 'assets/images/app_assets/info_bkg.png';
  static const String createHeroBackground =
      'assets/images/app_assets/create_hero_bkg.jpg';
}

IconData categoryIcon(QuestCategory category) => switch (category) {
  QuestCategory.health => Icons.favorite_rounded,
  QuestCategory.work => Icons.gavel_rounded,
  QuestCategory.study => Icons.menu_book_rounded,
  QuestCategory.home => Icons.castle_rounded,
  QuestCategory.social => Icons.groups_rounded,
  QuestCategory.creative => Icons.brush_rounded,
  QuestCategory.adventure => Icons.explore_rounded,
  QuestCategory.other => Icons.auto_awesome_rounded,
};

Color categoryColor(QuestCategory category) => Color(category.colorValue);

IconData originIcon(String? backgroundId) => switch (backgroundId) {
  'noble' => Icons.workspace_premium_rounded,
  'merchant' => Icons.paid_rounded,
  'soldier' => Icons.shield_rounded,
  'scholar' => Icons.menu_book_rounded,
  'orphan' => Icons.nightlight_round,
  'monk_train' => Icons.self_improvement_rounded,
  'hunter' => Icons.forest_rounded,
  'cursed' => Icons.bolt_rounded,
  _ => Icons.explore_rounded,
};

IconData achievementIcon(String id) => switch (id) {
  'first_quest' => Icons.auto_awesome_rounded,
  'first_level' => Icons.trending_up_rounded,
  'quest_master' => Icons.workspace_premium_rounded,
  'level_ten' => Icons.emoji_events_rounded,
  'stat_master' => Icons.bolt_rounded,
  'speedrunner' => Icons.speed_rounded,
  'perfectionist' => Icons.diamond_rounded,
  'balanced_hero' => Icons.balance_rounded,
  'specialist' => Icons.gps_fixed_rounded,
  'secret_hidden' => Icons.nightlight_round,
  _ => Icons.star_rounded,
};

IconData skillIcon(String id) => switch (id) {
  'power_strike' => Icons.flash_on_rounded,
  'swift_strike' => Icons.air_rounded,
  'fireball' => Icons.local_fire_department_rounded,
  'heal' => Icons.healing_rounded,
  'stealth' => Icons.visibility_off_rounded,
  'shield_bash' => Icons.shield_rounded,
  'mana_shield' => Icons.blur_circular_rounded,
  'whirlwind' => Icons.cyclone_rounded,
  _ => Icons.auto_fix_high_rounded,
};

Color skillCategoryColor(String category) => switch (category) {
  'combat' => const Color(0xFFE05A5A),
  'magic' => const Color(0xFFC542F5),
  'utility' => const Color(0xFF4FC3F7),
  'passive' => const Color(0xFF2EE6C5),
  _ => const Color(0xFFC89B5C),
};

Color rarityColor(int rarityScore) => switch (rarityScore) {
  1 => const Color(0xFFB8AFC9),
  2 => const Color(0xFF4FC3F7),
  3 => const Color(0xFFC542F5),
  4 => const Color(0xFFE8C46A),
  _ => const Color(0xFFE05A5A),
};

/// Short stat abbreviations used on the radar chart.
String statAbbreviation(String stat) => switch (stat) {
  'strength' => 'STR',
  'dexterity' => 'DEX',
  'intelligence' => 'INT',
  'wisdom' => 'WIS',
  'charisma' => 'CHA',
  'constitution' => 'CON',
  'luck' => 'LCK',
  _ => stat.toUpperCase(),
};
