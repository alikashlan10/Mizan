import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/profile/domain/profile.dart';

/// The saved profile; null until the user has filled it in.
final profileProvider = StreamProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);

/// Calorie figures for the saved profile; null when there is no profile.
final calorieEstimateProvider = Provider<CalorieEstimate?>((ref) {
  final profile = ref.watch(profileProvider).value;
  return profile == null ? null : estimateCalories(profile);
});
