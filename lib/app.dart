import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/habit_store.dart';
import 'ui/home/home_screen.dart';

/// アプリのルートウィジェット。UIは限りなくシンプルに。
class HabitApp extends StatelessWidget {
  final HabitStore store;

  const HabitApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'habit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
