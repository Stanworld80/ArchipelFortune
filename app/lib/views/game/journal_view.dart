import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';

class JournalView extends ConsumerWidget {
  const JournalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final entries = session.journalEntries.reversed.toList();
    final islandsVisited = session.discoveredIslandCoords.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6), // Parchment/Old paper
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF5D4037), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(context),
              _buildStats(session, islandsVisited),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Color(0xFF5D4037), thickness: 1.5, height: 1),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          "Aucune entrée dans le journal.",
                          style: TextStyle(
                            color: Colors.brown.shade800,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.brown.withOpacity(0.1)),
                        itemBuilder: (context, index) {
                          return _buildEntry(entries[index]);
                        },
                      ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF5D4037),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.history_edu, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            "JOURNAL DE BORD",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }  Widget _buildStats(SessionState session, int islandsVisited) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: "PACKETS",
            value: session.lootRemaining.toString(),
            icon: Icons.inventory_2,
            color: Colors.brown.shade700,
          ),
          _StatItem(
            label: "PROVISIONS",
            value: session.provisions.toString(),
            icon: Icons.restaurant,
            color: Colors.orange.shade800,
          ),
          _StatItem(
            label: "KITS RÉP.",
            value: session.boisCharpente.toString(),
            icon: Icons.build,
            color: Colors.blueGrey.shade700,
          ),
          _StatItem(
            label: "ÎLES",
            value: islandsVisited.toString(),
            icon: Icons.landscape,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(JournalEntry entry) {
    IconData icon;
    Color color;

    switch (entry.type) {
      case JournalEntryType.discovery:
        icon = Icons.explore;
        color = Colors.green.shade700;
        break;
      case JournalEntryType.incident:
        icon = Icons.warning_amber;
        color = Colors.red.shade700;
        break;
      case JournalEntryType.combat:
        icon = Icons.priority_high;
        color = Colors.orange.shade800;
        break;
      case JournalEntryType.start:
        icon = Icons.sailing;
        color = Colors.blue.shade700;
        break;
      case JournalEntryType.loot:
        icon = Icons.savings;
        color = Colors.amber.shade800;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blueGrey;
    }

    final timeStr = "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Heure locale : $timeStr",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5D4037),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "RETOUR À LA NAVIGATION",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? const Color(0xFF5D4037);
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.brown,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
