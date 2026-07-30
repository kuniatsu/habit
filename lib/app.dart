import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/app_catalog.dart';
import 'state/habit_store.dart';
import 'ui/main_screen.dart';

/// アプリのルートウィジェット。UIは限りなくシンプルに。
class HabitApp extends StatelessWidget {
  final HabitStore store;
  final AppCatalog appCatalog;

  const HabitApp({
    super.key,
    required this.store,
    this.appCatalog = const FamousAppCatalog(),
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        Provider<AppCatalog>.value(value: appCatalog),
      ],
      child: MaterialApp(
        title: 'habit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
