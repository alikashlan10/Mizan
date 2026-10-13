import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/diary/presentation/add_entry_dialog.dart';
import 'package:mizan/features/foods/domain/daily_targets.dart';
import 'package:mizan/features/foods/presentation/food_detail_screen.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';

/// The nutrition facts screen wired to the rest of the app: measured against
/// the user's own targets when they have a profile, and able to log to the
/// diary.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({required this.food, super.key});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimate = ref.watch(calorieEstimateProvider);
    final macros = ref.watch(macroTargetsProvider);

    return FoodDetailScreen(
      food: food,
      targets: estimate == null || macros == null
          ? const DailyTargets.reference()
          : DailyTargets(
              kcal: estimate.targetKcal,
              proteinG: macros.protein,
              carbsG: macros.carbs,
              fatG: macros.fat,
              isPersonal: true,
            ),
      onAddToDiary: (context, amount) async {
        final added = await showAddEntryDialog(context, food, amount: amount);
        if (!added || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${food.name} to the diary')),
        );
      },
    );
  }
}
