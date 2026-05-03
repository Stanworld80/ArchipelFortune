import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class AdminView extends ConsumerWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(firestoreServiceProvider).getAllUsers();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'ADMINISTRATION',
          header: true,
          container: true,
          child: const Text('Pannel d\'Administration'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider).signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Semantics(
                label: 'player_item_${user.uid}',
                container: true,
                child: ListTile(
                  title: Text(user.displayName),
                  subtitle: Text('${user.email} - Rôle: ${user.role}'),
                  trailing: Text('${user.piecesOr} 🪙', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () {
                    _showModifyUserDialog(context, ref, user);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showModifyUserDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final goldController = TextEditingController(text: user.piecesOr.toString());
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier ${user.displayName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'GOLD_INPUT',
                    textField: true,
                    child: TextField(
                      controller: goldController,
                      decoration: const InputDecoration(labelText: 'Pièces d\'Or'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: const [
                      DropdownMenuItem(value: 'player', child: Text('Joueur')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                      DropdownMenuItem(value: 'superAdmin', child: Text('Super Administrateur')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                Semantics(
                  label: 'SAVE_USER_BTN',
                  button: true,
                  onTap: () {
                    // Triggers logic
                  },
                  child: ElevatedButton(
                    key: const ValueKey('save_user_btn'),
                    onPressed: () async {
                      final newGold = int.tryParse(goldController.text) ?? user.piecesOr;
                      final firestore = ref.read(firestoreServiceProvider);
                      
                      if (newGold != user.piecesOr) {
                        await firestore.updateUserField(user.uid, 'piecesOr', newGold);
                      }
                      if (selectedRole != user.role) {
                        await firestore.updateUserField(user.uid, 'role', selectedRole);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Sauvegarder'),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
