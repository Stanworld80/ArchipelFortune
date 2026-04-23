import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';

class LootOverlay extends StatefulWidget {
  const LootOverlay({super.key});

  @override
  State<LootOverlay> createState() => _LootOverlayState();
}

class _LootOverlayState extends State<LootOverlay> {
  late List<_CrateContent> _crates;
  bool _allRevealed = false;
  bool _isAutoRevealing = false;
  bool _isSaving = false;
  
  int _goldGained = 0;
  
  // Tracking parts during stopover
  final Set<String> _repairPartsFound = {}; 
  int _provisionPartsFound = 0;
  
  // Completed kits
  int _repairKitsGained = 0;
  int _provisionKitsGained = 0;
  
  // Special items


  @override
  void initState() {
    super.initState();
    _goldGained = 0;
    _repairKitsGained = 0;
    _provisionKitsGained = 0;

    _repairPartsFound.clear();
    _provisionPartsFound = 0;
    _generateCrates();
  }

  void _generateCrates() {
    final rand = Random();
    _crates = List.generate(6, (_) {
      int roll = rand.nextInt(100);
      
      // -- Trash (20%)
      if (roll < 20) {
        final trash = ["Vieille botte", "Crochet rouillé", "Chapeau troué", "Boîte de conserve vide"];
        return _CrateContent(type: 'trash', value: 0, icon: Icons.delete_outline, color: Colors.grey, label: trash[rand.nextInt(trash.length)]);
      }
      
      // -- Or (30%)
      if (roll < 50) {
        int goldRoll = rand.nextInt(100);
        int pieceCount;
        if (goldRoll < 50) pieceCount = 2; // 50%
        else if (goldRoll < 80) pieceCount = 5; // 30%
        else if (goldRoll < 95) pieceCount = 10; // 15%
        else if (goldRoll < 99) pieceCount = 25; // 4%
        else pieceCount = 50; // 1%
        
        return _CrateContent(type: 'gold', value: pieceCount, icon: Icons.monetization_on, color: Colors.amber, label: "$pieceCount Or");
      }
      
      // -- Éléments Kit de réparation (20%)
      if (roll < 70) {
        final parts = [
          {'id':'outil', 'nom': 'Gros outil'}, 
          {'id':'bois', 'nom': 'Bois'}, 
          {'id':'materiel', 'nom': 'Petit matériel'}, 
          {'id':'cordes', 'nom': 'Cordes'}
        ];
        final part = parts[rand.nextInt(parts.length)];
        return _CrateContent(type: 'repair_part', value: 1, icon: Icons.build, color: Colors.brown, label: part['nom'], itemId: part['id']);
      }
      
      // -- Éléments Kit de provisions (30%)
      final provs = ['Poisson', 'Viande', 'Bouteille de vin', 'Eau'];
      final p = provs[rand.nextInt(provs.length)];
      return _CrateContent(type: 'prov_part', value: 1, icon: Icons.fastfood, color: Colors.redAccent, label: p);
    });
    
    _allRevealed = false;
    _isAutoRevealing = false;
  }

  void _processRevealedContent(_CrateContent content) {
    if (content.type == 'gold') {
      _goldGained += content.value;
    } else if (content.type == 'repair_part') {
      _repairPartsFound.add(content.itemId!);
      if (_repairPartsFound.length == 4) {
        _repairKitsGained++;
        _repairPartsFound.clear();
      }
    } else if (content.type == 'prov_part') {
       _provisionPartsFound++;
       if (_provisionPartsFound == 5) {
          _provisionKitsGained++;
          _provisionPartsFound = 0;
       }
    }
    
    if (_crates.every((c) => c.revealed)) {
      _allRevealed = true;
    }
  }

  Future<void> _autoRevealAll() async {
    if (_isAutoRevealing) return;
    setState(() => _isAutoRevealing = true);

    for (var crate in _crates) {
      if (!crate.revealed) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          crate.revealed = true;
          _processRevealedContent(crate);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ZONE DE BUTIN',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const Text(
              'Cliquez sur les caisses pour révéler leur contenu',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              width: 500,
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return _CrateWidget(
                    content: _crates[index],
                    onRevealed: (content) {
                      setState(() {
                        _processRevealedContent(content);
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            
            // Panneau de progression des kits (Toujours visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryItem(value: _goldGained, icon: Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text("Kits Rép.: $_repairKitsGained", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Pièces: ${_repairPartsFound.length}/4", style: const TextStyle(color: Colors.brown, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text("Kits Prov.: $_provisionKitsGained", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Pièces: $_provisionPartsFound/5", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            if (_isAutoRevealing && !_allRevealed)
              const CircularProgressIndicator(color: Colors.amber, strokeWidth: 6),
            const SizedBox(height: 20),
            Consumer(builder: (context, ref, child) {
              final session = ref.watch(sessionProvider);
              if (session == null) return const SizedBox.shrink();

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- BOUTON AUTO ---
                  _RoundActionButton(
                    icon: Icons.flash_on,
                    label: "AUTO",
                    color: Colors.blueAccent,
                    onPressed: (!_allRevealed && !_isAutoRevealing) ? _autoRevealAll : null,
                  ),
                  const SizedBox(width: 40),
                  // --- BOUTON SUIVANT ---
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_isSaving)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(color: Colors.amber),
                        )
                      else
                        _RoundActionButton(
                          icon: session.lootRemaining > 1 ? Icons.arrow_forward : Icons.check,
                          label: session.lootRemaining > 1 ? "SUIVANT" : "FIN",
                          color: Colors.amber,
                          onPressed: _allRevealed && !_isSaving ? () async {
                            if (session.lootRemaining > 1) {
                              // On passe au paquet suivant en gardant la progression
                              ref.read(sessionProvider.notifier).endLootSerie();
                              setState(() => _generateCrates());
                            } else {
                              setState(() => _isSaving = true);
                              // Fin du Loot - Les pièces incomplètes sont perdues
                              // On considère qu'un kit de provisions donne 5 unités de provisions au bateau
                              await ref.read(sessionProvider.notifier).addLootToCargaison(_goldGained, _provisionKitsGained * 5, _repairKitsGained);

                              if (mounted) {
                                ref.read(sessionProvider.notifier).endLootSerie();
                                setState(() => _isSaving = false);
                              }
                            }
                          } : null,
                        ),
                      if (session.lootRemaining > 1)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Center(
                              child: Text(
                                '${session.lootRemaining - 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }),

          ],
        ),
      ),
    );
  }
}

class _CrateContent {
  final String type;
  final int value;
  final IconData icon;
  final Color color;
  final String? label;
  final String? itemId;
  bool revealed = false;

  _CrateContent({
    required this.type, 
    required this.value, 
    required this.icon, 
    required this.color, 
    this.label,
    this.itemId,
  });
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isDisabled = onPressed == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.withAlpha(50) : color,
                shape: BoxShape.circle,
                border: Border.all(color: isDisabled ? Colors.white10 : Colors.white24, width: 3),
                boxShadow: isDisabled ? [] : [
                  BoxShadow(color: color.withAlpha(100), blurRadius: 12, spreadRadius: 2)
                ],
              ),
              child: Icon(icon, color: isDisabled ? Colors.white24 : Colors.brown.shade900, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDisabled ? Colors.white24 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _CrateWidget extends StatefulWidget {
  final _CrateContent content;
  final Function(_CrateContent) onRevealed;

  const _CrateWidget({required this.content, required this.onRevealed});

  @override
  State<_CrateWidget> createState() => _CrateWidgetState();
}

class _CrateWidgetState extends State<_CrateWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.content.revealed) {
          HapticFeedback.mediumImpact();
          setState(() => widget.content.revealed = true);
          widget.onRevealed(widget.content);
        }
      },
      child: AnimatedScale(
        scale: widget.content.revealed ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: widget.content.revealed ? Colors.white10 : Colors.brown.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.content.revealed ? widget.content.color : Colors.brown.shade400, width: 2),
            boxShadow: widget.content.revealed ? [BoxShadow(color: widget.content.color.withAlpha(130), blurRadius: 10)] : [],
          ),
          child: widget.content.revealed
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.content.icon, color: widget.content.color, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      widget.content.label ?? '${widget.content.value}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: widget.content.color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(Icons.inventory_2, color: Colors.white24, size: 40),
                ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryItem({required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text('$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

