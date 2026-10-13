import 'package:mizan/features/exercise/domain/exercise.dart';

extension ExerciseTypeLabel on ExerciseType {
  String get label => switch (this) {
    ExerciseType.walking => 'Walking',
    ExerciseType.running => 'Running',
    ExerciseType.weightLifting => 'Weight lifting',
  };
}
