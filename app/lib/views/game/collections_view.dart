import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';

class CollectionsView extends ConsumerWidget {
  const CollectionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final inventory = session?.inventory ?? [];

    final panoplies = [
      {
        'id': 'panoplie_explorateur',
        'name': 'Explorateur des Sables',
        'description': 'Les outils essentiels pour cartographier l\'inconnu.',
        'items': [
          {'id': 'boussole_antique', 'name': 'Boussole Antique'},
          {'id': 'longue-vue_en_ivoire', 'name': 'Longue-vue en Ivoire'},
          {'id': 'sextant_en_or', 'name': 'Sextant en Or'},
        ],
        'color': Colors.amber,
      },
      {
        'id': 'panoplie_pirate',
        'name': 'Collectionneur du Récif',
        'description': 'Objets perdus par ceux qui ont défié l\'Archipel.',
        'items': [
          {'id': 'sabre_rouille', 'name': 'Sabre Rouillé'},
          {'id': 'chapeau_de_capitaine', 'name': 'Chapeau de Capitaine'},
        ],
        'color': Colors.redAccent,
      },
    ];

    // Déterminer le statut 'collected' dynamiquement
    for (var panoplie in panoplies) {
      final items = panoplie['items'] as List<Map<String, String>>;
      panoplie['items_data'] = items.map((item) {
        return {
          ...item,
          'collected': inventory.contains(item['id']),
        };
      }).toList();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mes Collections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF002D20), Color(0xFF004D40)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
          itemCount: panoplies.length,
          itemBuilder: (context, index) {
            final panoplie = panoplies[index];
            final items = panoplie['items_data'] as List<Map<String, dynamic>>;
            final collectedCount = items.where((i) => i['collected'] == true).length;
            final progress = collectedCount / items.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: (panoplie['color'] as Color).withOpacity(0.5), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          panoplie['name'] as String,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: panoplie['color'] as Color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (panoplie['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$collectedCount / ${items.length}',
                            style: TextStyle(color: panoplie['color'] as Color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      panoplie['description'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      color: panoplie['color'] as Color,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: items.map((item) {
                        final isCollected = item['collected'] as bool;
                        return Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isCollected ? (panoplie['color'] as Color).withOpacity(0.2) : Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCollected ? panoplie['color'] as Color : Colors.white10,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                isCollected ? Icons.auto_awesome : Icons.lock_outline,
                                color: isCollected ? panoplie['color'] as Color : Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: Text(
                                item['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCollected ? Colors.white : Colors.white38,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
