import 'package:flutter/material.dart';

import 'history/history_tab.dart';
import 'home/home_tab.dart';
import 'register/preset_select_tab.dart';

/// フッターメニュー(TOP/登録/履歴)を持つメイン画面。
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _titles = ['habit', 'habitを選ぶ', 'habit履歴'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeTab(),
          PresetSelectTab(),
          HistoryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'TOP'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: '登録'),
          NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
        ],
      ),
    );
  }
}
