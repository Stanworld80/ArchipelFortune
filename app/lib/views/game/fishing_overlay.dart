import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';

class FishingOverlay extends ConsumerStatefulWidget {
  const FishingOverlay({super.key});

  @override
  ConsumerState<FishingOverlay> createState() => _FishingOverlayState();
}

class _FishingOverlayState extends ConsumerState<FishingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _oscillation;
  bool _isFishing = false;
  bool _hasFished = false;
  String? _resultMessage;
  IconData? _resultIcon;
  Color? _resultColor;
  
  int _extraNets = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _oscillation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _throwNet() async {
    if (_isFishing || _hasFished && _extraNets <= 0) return;
    
    setState(() {
      _isFishing = true;
      _resultMessage = "Le filet est à l'eau...";
    });

    // Simulation de l'attente
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final rand = Random();
    final chance = rand.nextInt(100);
    
    String msg;
    IconData icon;
    Color color;
    int gold = 0;
    int food = 0;
    int wood = 0;
    String? itemId;

    if (chance < 40) {
      msg = "Bredouille... La mer est calme.";
      icon = Icons.waves;
      color = Colors.blueGrey;
    } else if (chance < 70) {
      food = rand.nextInt(5) + 2;
      msg = "Belle prise ! +$food Poissons";
      icon = Icons.set_meal;
      color = Colors.orange;
    } else if (chance < 85) {
      gold = (rand.nextInt(5) + 1) * 10;
      msg = "Un vieux coffre ! +$gold Or";
      icon = Icons.monetization_on;
      color = Colors.amber;
    } else if (chance < 95) {
        _extraNets++;
        msg = "Un filet de pêche supplémentaire ! Rejouez.";
        icon = Icons.add_circle;
        color = Colors.green;
    } else {
      itemId = "perle_noire";
      msg = "INCROYABLE ! Une Perle Noire !";
      icon = Icons.auto_awesome;
      color = Colors.purpleAccent;
    }

    setState(() {
      _isFishing = false;
      _resultMessage = msg;
      _resultIcon = icon;
      _resultColor = color;
      if (_extraNets > 0 && chance < 95) {
        // use extra net doesn't count as final finish if we just used it
      } else if (chance >= 95 || _extraNets == 0) {
          _hasFished = true;
      }
    });

    // Appliquer le loot
    final notifier = ref.read(sessionProvider.notifier);
    if (gold > 0 || food > 0 || wood > 0) {
      notifier.addLootToCargaison(gold, food, wood);
    }
    if (itemId != null) {
      notifier.addSpecialLoot(itemId: itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SESSION DE PÊCHE',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            Text(
              _extraNets > 0 ? 'Filets restants : $_extraNets' : 'Tentez votre chance !',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 50),
            
            // L'oscillation visuelle du filet
            AnimatedBuilder(
              animation: _oscillation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_oscillation.value * 100, 0),
                  child: Transform.rotate(
                    angle: _oscillation.value * 0.2,
                    child: const Icon(Icons.sailing, color: Colors.white, size: 80),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Le filet sous le bateau
            AnimatedBuilder(
              animation: _oscillation,
              builder: (context, child) {
                 return Transform.translate(
                  offset: Offset(_oscillation.value * 80, 20),
                  child: Icon(
                    Icons.grid_on, 
                    color: _isFishing ? Colors.amber : Colors.white24, 
                    size: 60
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            if (_resultMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _resultColor ?? Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_resultIcon != null) Icon(_resultIcon, color: _resultColor, size: 30),
                    const SizedBox(width: 15),
                    Text(
                      _resultMessage!,
                      style: TextStyle(color: _resultColor ?? Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            if (!_hasFished || _extraNets > 0)
              ElevatedButton.icon(
                icon: Icon(_isFishing ? Icons.hourglass_bottom : Icons.anchor),
                label: Text(_isFishing ? 'RECRANT...' : (_extraNets > 0 ? 'RELANCER LE FILET' : 'LANCER LE FILET')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: _isFishing ? null : _throwNet,
              ),

            if (_hasFished && _extraNets <= 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: () {
                  ref.read(sessionProvider.notifier).endLootSerie();
                  ref.read(sessionProvider.notifier).resumeExpedition();
                },
                child: const Text('REPRENDRE LA NAVIGATION', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }
}
