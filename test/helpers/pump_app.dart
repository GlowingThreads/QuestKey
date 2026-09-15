import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import 'fake_asset_bundle.dart';

/// Pumps [child] inside a MaterialApp with the app's providers and a fake
/// asset bundle.
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  required AppState appState,
  required QuestListProvider questProvider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<QuestListProvider>.value(value: questProvider),
      ],
      child: DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}
