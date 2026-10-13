import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/diary/presentation/add_entry_dialog.dart';
import 'package:mizan/features/diary/presentation/diary_screen.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/foods/presentation/food_search_screen.dart';

/// Root of the app: the bottom navigation bar and its tabs.
///
/// Phase 2 adds a Workouts tab between Foods and Statistics.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Start importing the bundled foods as soon as the app opens.
    ref.watch(foodSeedProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const DiaryScreen(),
          FoodSearchScreen(
            onFoodSelected: (context, food) async {
              final added = await showAddEntryDialog(context, food);
              if (!added || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${food.name} to the diary')),
              );
            },
          ),
          const _ComingSoon(title: 'Statistics'),
          const _ComingSoon(title: 'Profile'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Foods',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
