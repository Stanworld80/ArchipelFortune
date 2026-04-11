import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';

class UpgradeShopView extends ConsumerWidget {
  const UpgradeShopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(session.orVolatil),
          const SizedBox(height: 20),
          _buildUpgradeItem(
            context,
            ref,
            icon: Icons.shield,
            title: "Coque Renforcée",
            description: "Augmente la résistance et la capacité de bois.",
            level: session.hullLevel,
            cost: 100 * session.hullLevel,
            canAfford: session.orVolatil >= (100 * session.hullLevel),
            onUpgrade: () => ref.read(sessionProvider.notifier).upgradeHull(),
          ),
          _buildUpgradeItem(
            context,
            ref,
            icon: Icons.air,
            title: "Voiles de Soie",
            description: "Réduit la consommation de provisions.",
            level: session.sailsLevel,
            cost: 100 * session.sailsLevel,
            canAfford: session.orVolatil >= (100 * session.sailsLevel),
            onUpgrade: () => ref.read(sessionProvider.notifier).upgradeSails(),
          ),
          _buildUpgradeItem(
            context,
            ref,
            icon: Icons.inventory_2,
            title: "Soute Optimisée",
            description: "Augmente le butin d'or trouvé en escale.",
            level: session.cargoLevel,
            cost: 100 * session.cargoLevel,
            canAfford: session.orVolatil >= (100 * session.cargoLevel),
            onUpgrade: () => ref.read(sessionProvider.notifier).upgradeCargo(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("RETOUR AU NAVIRE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int gold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "ATELIER NAVAL",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 5),
              Text(
                "$gold",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String description,
    required int level,
    required int cost,
    required bool canAfford,
    required VoidCallback onUpgrade,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Niv. $level", style: TextStyle(color: Colors.amber.shade200, fontSize: 12)),
                    ],
                  ),
                  Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 8),
                  _buildProgressBar(level),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Column(
              children: [
                Text("$cost G", style: TextStyle(color: canAfford ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: canAfford ? onUpgrade : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: Colors.amber,
                  disabledColor: Colors.white10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int level) {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index < level ? Colors.amber : Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
