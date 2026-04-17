import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: ListView(
        children: const [
          ExpansionTile(
            title: Text('Comment utiliser l\'application ?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'L\'application est conçue pour être intuitive. Naviguez via le menu pour découvrir ses différentes fonctionnalités.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Comment réinitialiser mon mot de passe ?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Allez sur la page de connexion, cliquez sur "Mot de passe oublié" et suivez les instructions envoyées par e-mail.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Mes données sont-elles sécurisées ?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Oui, nous accordons une grande importance à la sécurité de vos données. Consultez notre politique de confidentialité pour plus de détails.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Comment contacter le support ?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Vous pouvez nous contacter via la page "Contact" accessible depuis le menu "À propos".'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
