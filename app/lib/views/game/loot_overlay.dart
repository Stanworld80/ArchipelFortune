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
  int _goldGained = 0;
  int _provGained = 0;
  int _woodGained = 0;

  @override
  void initState() {
    super.initState();
    _generateCrates();
  }

  void _generateCrates() {
    final rand = Random();
    _crates = List.generate(6, (_) {
      int type = rand.nextInt(100);
      if (type < 35) return _CrateContent(type: 'gold', value: (rand.nextInt(10) + 5) * 10, icon: Icons.monetization_on, color: Colors.amber);
      if (type < 60) return _CrateContent(type: 'provisions', value: rand.nextInt(5) + 3, icon: Icons.apple, color: Colors.red);
      if (type < 75) return _CrateContent(type: 'wood', value: 1, icon: Icons.handyman, color: Colors.brown);
      
      // Nouvelles récompenses rares
      if (type < 85) {
        final keyTypes = ['copper', 'silver', 'gold'];
        final kt = keyTypes[rand.nextInt(3)];
        return _CrateContent(
          type: 'key', 
          value: 1, 
          icon: Icons.key, 
          color: kt == 'gold' ? Colors.yellow : (kt == 'silver' ? Colors.grey : Colors.orange), 
          label: kt.toUpperCase(),
          keyType: kt,
        );
      }
      
      if (type < 95) {
        final items = ['Boussole Antique', 'Longue-vue en Ivoire', 'Sextant en Or', 'Sabre Rouillé', 'Chapeau de Capitaine'];
        final item = items[rand.nextInt(items.length)];
        return _CrateContent(type: 'item', value: 1, icon: Icons.auto_awesome, color: Colors.purple, label: item, itemId: item.toLowerCase().replaceAll(' ', '_'));
      }

      return _CrateContent(type: 'map', value: 1, icon: Icons.map, color: Colors.tealAccent, label: "Carte mystérieuse");
    });
    _allRevealed = false;
    _isAutoRevealing = false;
    _goldGained = 0;
    _provGained = 0;
    _woodGained = 0;
  }

  void _processRevealedContent(_CrateContent content) {
    if (content.type == 'gold') _goldGained += content.value;
    if (content.type == 'provisions') _provGained += content.value;
    if (content.type == 'wood') _woodGained += content.value;
    
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
            const SizedBox(height: 40),
            Container(
              width: 400,
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
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            if (_isAutoRevealing && !_allRevealed)
              const CircularProgressIndicator(color: Colors.amber, strokeWidth: 6),
            const SizedBox(height: 20),
            if (_allRevealed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SummaryItem(value: _goldGained, icon: Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 20),
                    _SummaryItem(value: _provGained, icon: Icons.apple, color: Colors.red),
                    const SizedBox(width: 20),
                    _SummaryItem(value: _woodGained, icon: Icons.handyman, color: Colors.brown),
                  ],
                ),
              ),
            const SizedBox(height: 30),
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
                      _RoundActionButton(
                        icon: session.lootRemaining > 1 ? Icons.arrow_forward : Icons.check,
                        label: session.lootRemaining > 1 ? "SUIVANT" : "FIN",
                        color: Colors.amber,
                        onPressed: _allRevealed ? () {
                          // Ajouter le butin à la cargaison
                          ref.read(sessionProvider.notifier).addLootToCargaison(_goldGained, _provGained, _woodGained);
                          
                          // Ajouter les items spéciaux trouvés
                          for (var crate in _crates) {
                            if (crate.type == 'key' || crate.type == 'item') {
                              ref.read(sessionProvider.notifier).addSpecialLoot(
                                keyType: crate.keyType,
                                itemId: crate.itemId,
                              );
                            }
                            if (crate.type == 'map') {
                              ref.read(sessionProvider.notifier).addDiscoveryMap();
                            }
                          }

                          ref.read(sessionProvider.notifier).endLootSerie();
                          
                          if (session.lootRemaining > 1) {
                            setState(() => _generateCrates());
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
  final String? keyType;
  final String? itemId;
  bool revealed = false;

  _CrateContent({
    required this.type, 
    required this.value, 
    required this.icon, 
    required this.color, 
    this.label,
    this.keyType,
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
                color: isDisabled ? Colors.grey.withValues(alpha: 0.2) : color,
                shape: BoxShape.circle,
                border: Border.all(color: isDisabled ? Colors.white10 : Colors.white24, width: 3),
                boxShadow: isDisabled ? [] : [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)
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
            boxShadow: widget.content.revealed ? [BoxShadow(color: widget.content.color.withValues(alpha: 0.5), blurRadius: 10)] : [],
          ),
          child: widget.content.revealed
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.content.icon, color: widget.content.color, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      widget.content.label ?? '+${widget.content.value}',
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
