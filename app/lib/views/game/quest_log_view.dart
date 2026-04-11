import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';

class QuestLogView extends ConsumerWidget {
  const QuestLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFE5D3B3), // Couleur parchemin
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
        ],
        border: Border.all(color: const Color(0xFF8B4513), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: session.quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                return _buildQuestItem(session.quests[index]);
              },
            ),
          ),
          const SizedBox(height: 25),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.history_edu, color: Color(0xFF8B4513), size: 40),
        SizedBox(height: 5),
        Text(
          "JOURNAL D'AVENTURE",
          style: TextStyle(
            fontFamily: 'Serif',
            color: Color(0xFF8B4513),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Divider(color: Color(0xFF8B4513), thickness: 1, indent: 40, endIndent: 40),
      ],
    );
  }

  Widget _buildQuestItem(Quest quest) {
    final double progress = quest.currentValue / quest.targetValue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: quest.isCompleted ? Colors.green : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quest.title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: quest.isCompleted ? Colors.green.shade800 : const Color(0xFF5D4037),
                    fontSize: 16,
                  ),
                ),
              ),
              if (quest.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                _buildRewardBadge(quest.rewardType, quest.rewardAmount),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            style: const TextStyle(color: Color(0xFF795548), fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(progress, quest.isCompleted),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${quest.currentValue} / ${quest.targetValue}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(RewardType type, int amount) {
    IconData icon;
    Color color;
    switch (type) {
      case RewardType.gold: icon = Icons.monetization_on; color = Colors.orange; break;
      case RewardType.keyCopper: icon = Icons.key; color = Colors.brown; break;
      case RewardType.keySilver: icon = Icons.key; color = Colors.grey; break;
      case RewardType.keyGold: icon = Icons.key; color = Colors.amber; break;
      default: icon = Icons.card_giftcard; color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text("x$amount", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, bool isCompleted) {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted 
                ? [Colors.green, Colors.greenAccent] 
                : [const Color(0xFF8B4513), const Color(0xFFA0522D)],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        "CONTINUER L'AVENTURE",
        style: TextStyle(
          color: Color(0xFF8B4513),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
