import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../admin/admin_view.dart';
import '../game/collections_view.dart';
import '../game/game_dashboard_view.dart';
import '../../models/user_model.dart';
import '../../core/widgets/sprite_button.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _titleCtrl;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleFade = CurvedAnimation(parent: _titleCtrl, curve: Curves.easeIn);
    _titleCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final sz = MediaQuery.of(context).size;
    final isWide = sz.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 0,
        title: null,
        actions: [
          // Admin + logout menu
          userProfileAsync.maybeWhen(
            data: (profile) => profile == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'admin') {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminView()),
                        );
                      } else if (value == 'logout') {
                        ref.read(authControllerProvider).signOut();
                      }
                    },
                    child: Semantics(
                      label: 'PROFILE_BTN',
                      button: true,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFD4AF37), width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88D4AF37),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF3D2B1F),
                          child: Icon(Icons.person, color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      if (profile.role == 'admin' ||
                          profile.role == 'superAdmin')
                        const PopupMenuItem<String>(
                          value: 'admin',
                          child: ListTile(
                            leading: Icon(Icons.admin_panel_settings,
                                color: Color(0xFF3D2B1F)),
                            title: Text('Panel Admin'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading:
                              Icon(Icons.logout, color: Colors.redAccent),
                          title: Text('Déconnexion'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF5C3317), // warm leather center
                  Color(0xFF2B1810), // deep mahogany
                  Color(0xFF0D0906), // almost black edges
                ],
              ),
            ),
          ),

          // Subtle sea-wave texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/images/buttons_sprite.png',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.luminosity,
                color: Colors.white,
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48.0 : 20.0,
                  vertical: 8,
                ),
                child: userProfileAsync.when(
                  data: (profile) {
                    if (profile == null) {
                      return const Center(
                        child: Text('Profil non trouvé.',
                            style: TextStyle(color: Colors.white)),
                      );
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 12),

                        // ── Title ───────────────────────────────────
                        FadeTransition(
                          opacity: _titleFade,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFF5DEB3), // wheat
                                Color(0xFFD4AF37), // gold
                                Color(0xFFF5DEB3), // wheat
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(bounds),
                            child: Text(
                              "L'Archipel\nde la Fortune",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzelDecorative(
                                fontSize: isWide ? 52 : 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Decorative divider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoldDivider(width: isWide ? 120 : 70),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.anchor,
                                  color: Color(0xFFD4AF37), size: 20),
                            ),
                            _GoldDivider(width: isWide ? 120 : 70),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Player info card ─────────────────────────
                        _PlayerCard(profile: profile, isWide: isWide),

                        const SizedBox(height: 32),

                        // ── DÉPART (hero button) ─────────────────────
                        SpriteButton(
                          semanticLabel: 'EXPLORE_MAIN_BTN',
                          spriteRect: SpriteRegions.depart,
                          width: isWide ? 280 : 200,
                          height: isWide ? 280 : 200,
                          onTap: () =>
                              _showPreparationDialog(context, ref, profile),
                        ),

                        const SizedBox(height: 8),

                        // ── Second row: INVENTAIRE + CARTE ────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // INVENTAIRE / Collections
                            SpriteButton(
                              semanticLabel: 'COLLECTIONS_BTN',
                              spriteRect: SpriteRegions.inventaire,
                              width: isWide ? 160 : 120,
                              height: isWide ? 160 : 120,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CollectionsView(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // CARTE — placeholder (map view future)
                            SpriteButton(
                              semanticLabel: 'MAP_BTN',
                              spriteRect: SpriteRegions.carte,
                              width: isWide ? 160 : 120,
                              height: isWide ? 140 : 100,
                              disabled: true, // à activer quand Map View existe
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Third row: RÉGLAGES + VOYAGE + DÉFI ──────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // RÉGLAGES
                            SpriteButton(
                              semanticLabel: 'SETTINGS_BTN',
                              spriteRect: SpriteRegions.reglages,
                              width: isWide ? 100 : 76,
                              height: isWide ? 100 : 76,
                              disabled: true, // future
                              onTap: () {},
                            ),

                            const SizedBox(width: 12),

                            // VOYAGE (active = trigger explore)
                            SpriteButton(
                              semanticLabel: 'VOYAGE_BTN',
                              spriteRect: SpriteRegions.voyage,
                              width: isWide ? 240 : 180,
                              height: isWide ? 80 : 60,
                              onTap: () =>
                                  _showPreparationDialog(context, ref, profile),
                            ),

                            const SizedBox(width: 12),

                            // DÉFI
                            SpriteButton(
                              semanticLabel: 'DEFI_BTN',
                              spriteRect: SpriteRegions.defi,
                              width: isWide ? 100 : 76,
                              height: isWide ? 100 : 76,
                              disabled: true, // future
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Tagline
                        Text(
                          'Une aventure d\'exploration, de découvertes\net de fortune vous attend...',
                          style: GoogleFonts.crimsonText(
                            fontSize: 16,
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('Erreur: $err',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gold pieces + role card ─────────────────────────────────────────────────
  void _showPreparationDialog(
      BuildContext context, WidgetRef ref, UserModel profile) {
    int provisionsToBuy = 20;
    int woodToBuy = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int totalCost =
                (provisionsToBuy ~/ 10) * 5 + (woodToBuy * 10);
            bool canAfford = profile.piecesOr >= totalCost;

            return AlertDialog(
              backgroundColor: const Color(0xFF2B1810),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
              title: Text(
                'Préparation du Navire',
                style: GoogleFonts.cinzelDecorative(
                    color: const Color(0xFFD4AF37), fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Combien de provisions et de bois souhaitez-vous emporter ?',
                    style: GoogleFonts.crimsonText(
                        color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _SupplyRow(
                    icon: Icons.apple,
                    iconColor: Colors.redAccent,
                    label: 'Provisions ($provisionsToBuy)',
                    onDecrement: provisionsToBuy > 10
                        ? () => setState(() => provisionsToBuy -= 10)
                        : null,
                    onIncrement: () => setState(() => provisionsToBuy += 10),
                  ),
                  _SupplyRow(
                    icon: Icons.handyman,
                    iconColor: Colors.brown.shade300,
                    label: 'Bois ($woodToBuy)',
                    onDecrement: woodToBuy > 0
                        ? () => setState(() => woodToBuy -= 1)
                        : null,
                    onIncrement: () => setState(() => woodToBuy += 1),
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coût Total:',
                          style: GoogleFonts.crimsonText(
                              color: Colors.white, fontSize: 16)),
                      Text(
                        '$totalCost 🪙',
                        style: TextStyle(
                          color: canAfford
                              ? const Color(0xFFD4AF37)
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (!canAfford)
                    const Text('Or insuffisant !',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler',
                      style: GoogleFonts.crimsonText(
                          color: Colors.white54, fontSize: 15)),
                ),
                ElevatedButton(
                  onPressed: canAfford
                      ? () async {
                          setState(() => _isLoading = true);
                          try {
                            final firestoreService =
                                ref.read(firestoreServiceProvider);
                            await firestoreService.updateUserField(
                                profile.uid,
                                'piecesOr',
                                profile.piecesOr - totalCost);

                            const int? testSeed =
                                bool.hasEnvironment('TEST_SEED')
                                    ? int.fromEnvironment('TEST_SEED')
                                    : null;

                            await ref
                                .read(sessionProvider.notifier)
                                .startNewSession(
                                  startingProvisions: provisionsToBuy,
                                  startingBois: woodToBuy,
                                  seed: testSeed,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const GameDashboardView()),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF2B1810),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2B1810),
                          ),
                        )
                      : Text('Prendre la Mer 🚢',
                          style: GoogleFonts.cinzelDecorative(fontSize: 14)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.profile, required this.isWide});
  final UserModel profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44D4AF37),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            profile.displayName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: isWide ? 26 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '${profile.piecesOr} Pièces d\'Or',
                style: GoogleFonts.crimsonText(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.role.toUpperCase(),
            style: GoogleFonts.crimsonText(
              fontSize: 13,
              color: Colors.white38,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onIncrement,
    this.onDecrement,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.white54, size: 26),
            onPressed: onDecrement,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFFD4AF37), size: 26),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
