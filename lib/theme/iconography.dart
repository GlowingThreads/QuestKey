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
  // The Road
  'first_quest' => Icons.auto_awesome_rounded,
  'first_level' => Icons.trending_up_rounded,
  'streak_3' => Icons.local_fire_department_outlined,
  'level_five' => Icons.military_tech_rounded,
  'quest_master' => Icons.workspace_premium_rounded,
  'level_ten' => Icons.emoji_events_rounded,
  'quest_50' => Icons.shield_rounded,
  'quest_100' => Icons.account_balance_rounded,
  'level_twenty' => Icons.star_rounded,
  'title_worn' => Icons.badge_rounded,
  // Trials
  'speedrunner' => Icons.speed_rounded,
  'perfectionist' => Icons.diamond_rounded,
  'streak_30' => Icons.whatshot_rounded,
  'epic_first' => Icons.pets_rounded,
  'punctual' => Icons.timer_rounded,
  'lucky_strike' => Icons.casino_rounded,
  'crit_10' => Icons.casino_outlined,
  'boss_slayer' => Icons.security_rounded,
  'boss_5' => Icons.gavel_rounded,
  'torch_bearer' => Icons.local_fire_department_rounded,
  'bulwark' => Icons.shield_moon_rounded,
  'secret_hidden' => Icons.nightlight_round,
  'early_bird' => Icons.wb_twilight_rounded,
  'weekend_warrior' => Icons.holiday_village_rounded,
  'ashes' => Icons.flare_rounded,
  // Mastery
  'stat_master' => Icons.bolt_rounded,
  'balanced_hero' => Icons.balance_rounded,
  'specialist' => Icons.gps_fixed_rounded,
  'paragon' => Icons.hexagon_rounded,
  'first_skill' => Icons.history_edu_rounded,
  'spell_caster' => Icons.auto_fix_high_rounded,
  'spell_master' => Icons.auto_awesome_motion_rounded,
  'spell_100' => Icons.blur_on_rounded,
  'enchanter' => Icons.auto_awesome_outlined,
  'loremaster' => Icons.menu_book_rounded,
  // Wayfaring
  'encounter_victor' => Icons.map_rounded,
  'wayfarer' => Icons.explore_rounded,
  'well_rounded' => Icons.public_rounded,
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
  'meditate' => Icons.self_improvement_rounded,
  'second_wind' => Icons.favorite_rounded,
  'enchant' => Icons.auto_awesome_rounded,
  'battle_cry' => Icons.campaign_rounded,
  'chronoshift' => Icons.hourglass_top_rounded,
  'foresight' => Icons.remove_red_eye_rounded,
  'berserk' => Icons.bloodtype_rounded,
  'divine_favour' => Icons.church_rounded,
  'scholars_focus' => Icons.menu_book_rounded,
  'iron_will' => Icons.link_rounded,
  'keen_edge' => Icons.content_cut_rounded,
  _ => Icons.auto_fix_high_rounded,
};

Color skillCategoryColor(String category) => switch (category) {
  'combat' => const Color(0xFFE05A5A),
  'magic' => const Color(0xFFC542F5),
  'utility' => const Color(0xFF4FC3F7),
  'passive' => const Color(0xFF2EE6C5),
  _ => const Color(0xFFC89B5C),
};

/// Heading for a skill school in the grimoire.
String skillSchoolLabel(String category) => switch (category) {
  'combat' => 'Martial Arts',
  'magic' => 'Arcana',
  'utility' => 'Craft',
  'passive' => 'Disciplines',
  _ => category,
};

IconData skillSchoolIcon(String category) => switch (category) {
  'combat' => Icons.gavel_rounded,
  'magic' => Icons.auto_awesome_rounded,
  'utility' => Icons.handyman_rounded,
  'passive' => Icons.self_improvement_rounded,
  _ => Icons.star_rounded,
};

IconData achievementCategoryIcon(String category) => switch (category) {
  'progress' => Icons.signpost_rounded,
  'challenge' => Icons.local_fire_department_rounded,
  'mastery' => Icons.school_rounded,
  'exploration' => Icons.explore_rounded,
  _ => Icons.star_rounded,
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
