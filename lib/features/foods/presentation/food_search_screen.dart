import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/presentation/food_form_screen.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

/// Searches foods and reports the one the user taps. What happens with the
/// chosen food is up to the caller.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    required this.onFoodSelected,
    this.autofocus = false,
    super.key,
  });

  final Future<void> Function(BuildContext context, Food food) onFoodSelected;
  final bool autofocus;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  String _query = '';

  /// The source tab being searched; null is the "All" tab.
  String? _source;

  /// Results of the previous query, shown until the new ones arrive.
  List<Food>? _foods;

  void _createFood() {
    Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const FoodFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final seeding = ref.watch(foodSeedProvider).isLoading;
    final sources = ref.watch(foodSourcesProvider).value ?? const [];
    // The selected source can disappear, for example when its last custom
    // food is deleted.
    final source = sources.contains(_source) ? _source : null;
    final foods = _foods =
        ref.watch(foodSearchProvider((query: _query, source: source))).value ??
        _foods;
    final tabs = <String?>[null, ...sources];

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: DefaultTabController(
            // A new controller whenever the set of tabs changes.
            key: ValueKey(tabs.join('|')),
            length: tabs.length,
            initialIndex: tabs.indexOf(source),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final tab in tabs)
                  Tab(text: tab == null ? 'All' : FoodSources.label(tab)),
              ],
              onTap: (i) => setState(() => _source = tabs[i]),
            ),
          ),
        ),
        title: TextField(
          autofocus: widget.autofocus,
          decoration: const InputDecoration(
            hintText: 'Search foods',
            border: InputBorder.none,
          ),
          onChanged: (query) => setState(() => _query = query),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create food',
            onPressed: _createFood,
          ),
        ],
      ),
      body: switch (foods) {
        null => const Center(child: CircularProgressIndicator()),
        [] when seeding => const _PreparingFoods(),
        [] => _NoFoods(onCreateFood: _createFood),
        _ => ListView.builder(
          itemCount: foods.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(foods[i].name),
            subtitle: Text(FoodSources.label(foods[i].source)),
            onTap: () => widget.onFoodSelected(context, foods[i]),
          ),
        ),
      },
    );
  }
}

class _PreparingFoods extends StatelessWidget {
  const _PreparingFoods();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing the food database…'),
        ],
      ),
    );
  }
}

class _NoFoods extends StatelessWidget {
  const _NoFoods({required this.onCreateFood});

  final VoidCallback onCreateFood;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No foods found'),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create food'),
            onPressed: onCreateFood,
          ),
        ],
      ),
    );
  }
}
