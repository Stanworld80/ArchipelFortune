import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/session_model.dart';

void main() {
  group('Quest Model Tests', () {
    test('Quest.fromMap and Quest.toMap should be consistent', () {
      final quest = Quest(
        id: 'test_quest',
        title: 'Test Title',
        description: 'Test Description',
        currentValue: 5,
        targetValue: 10,
        isCompleted: false,
        rewardType: RewardType.gold,
        rewardAmount: 100,
      );

      final map = quest.toMap();
      final reconstructedQuest = Quest.fromMap(map);

      expect(reconstructedQuest.id, quest.id);
      expect(reconstructedQuest.title, quest.title);
      expect(reconstructedQuest.description, quest.description);
      expect(reconstructedQuest.currentValue, quest.currentValue);
      expect(reconstructedQuest.targetValue, quest.targetValue);
      expect(reconstructedQuest.isCompleted, quest.isCompleted);
      expect(reconstructedQuest.rewardType, quest.rewardType);
      expect(reconstructedQuest.rewardAmount, quest.rewardAmount);
    });

    test('Quest.copyWith should create a new instance with updated values', () {
      final quest = Quest(
        id: 'test_quest',
        title: 'Test Title',
        description: 'Test Description',
        currentValue: 5,
        targetValue: 10,
        rewardType: RewardType.gold,
        rewardAmount: 100,
      );

      final updatedQuest = quest.copyWith(currentValue: 6, isCompleted: true);

      expect(updatedQuest.id, quest.id);
      expect(updatedQuest.currentValue, 6);
      expect(updatedQuest.isCompleted, true);
      expect(updatedQuest.targetValue, quest.targetValue);
    });
  });
}
