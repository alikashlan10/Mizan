import 'package:flutter/material.dart';
import 'package:mizan/features/statistics/presentation/tabs/macros_tab.dart';
import 'package:mizan/features/statistics/presentation/tabs/nutrients_tab.dart';
import 'package:mizan/features/statistics/presentation/tabs/overview_tab.dart';
import 'package:mizan/features/statistics/presentation/widgets/range_bar.dart';

/// Statistics over a chosen range of days, in three tabs that share the range.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Macros'),
              Tab(text: 'Nutrients'),
            ],
          ),
        ),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RangeBar(),
            Expanded(
              child: TabBarView(
                children: [OverviewTab(), MacrosTab(), NutrientsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
