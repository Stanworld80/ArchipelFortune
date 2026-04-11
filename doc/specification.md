# Spécification Technique & Documentation : L'Archipel de la Fortune

## 1. Introduction

**L'Archipel de la Fortune** est un jeu d'exploration et de gestion de ressources dont le but est d'explorer un océan généré de manière procédurale pour amasser des richesses et des trésors perdus. Le joueur incarne un Capitaine de navire naviguant à l'ère des grandes découvertes. Chaque expédition est un voyage sans retour possible nécessitant une gestion rigoureuse des vivres (Provisions) et des risques liés à la navigation. Beaucoup de hazard et trés trés peu de stratégie déterminent le succès ou l'échec du joueur. (C'est un jeu de hasard)

Ce document décrit les spécifications techniques et les règles métiers nécessaires pour développer ce jeu à la fois sur le **Web** et sur **Android** en utilisant le framework **Flutter**.

---

## 2. Le Modèle de Jeu et l'Économie

L'économie du jeu repose sur une combinaison de ressources persistantes (conservées entre chaque session : les piéces d'or) et volatiles (tout le reste, lié à la session en cours).

### 2.1 Les Ressources

- **Pièces d'Or Sécurisées (Permanentes) :** Richesse totale du joueur, sauvegardée sur son profil (Firebase/Firestore). Elles sont utilisées pour préparer l'expédition ou acheter des provisions depuis les banques.
- **Or en main (Volatil) :** Richesses récoltées durant l'expédition courante. Elles sont stockées sur le navire et peuvent être perdues en cas de naufrage (Game Over).
- **Les Provisions (🍎) :** Denrées achetables au début et pendant un voyage. Chaque déplacement du navire consomme exactement 1 Provision. Si les provisions tombent à 0 en mer, le navire est perdu (Famine  donc Game Over).
- **Le Bois de Charpente (Joker) :** Ressource volatile servant de "bouclier". À l'impact avec un Récif, le bois est consommé pour sauver le bateau du naufrage.

---

## 3. Le Déroulement du Jeu

### Phase 1 : Le Port de Départ

Le jeu commence sur une ile sécurisée (Port de Départ) à un endroit aléatoire de la carte.
- **Investissement initial :** Le joueur dépense ses Pièces d'Or pour acheter des Provisions.
- **Récompense de départ :** Le joueur a droit à un "grattage" gratuit de caisses de ravitaillement pour obtenir un petit bonus (Provisions additionnelles ou Bois de Charpente).

### Phase 2 : En Haute Mer
- **Carte :** Matrice générée de **36x36** cases. Elle n'est générée et connue que côté serveur (Anti-Cheat).
- **Vision (Limitation) :** Le joueur n'a qu'un aperçu d'une grille **5x5** autour du navire. Le reste est caché (Brouillard de guerre).
- **Position d'affichage :** Le navire reste fixe au centre de la vue. Ce sont les éléments de la carte qui glissent.
- **Les Dangers (Récifs) :** Naviguer sur un récif à 50% de chance de détruire le navire (Game Over) à moins de posséder du Bois de Charpente, il est alors automatiquement consommé si besoin.

**Mouvements & Navigation relative (Coût : 1 Provision)** :
Aucun retour en arrière n'est permis. Le jeu se joue sur une rotation de 90° :
- **Avancer :** Avance tout droit selon le cap actuel d'une case.
- **Bâbord :** Tourne de -90° puis avance d'une case.
- **Tribord :** Tourne de +90° puis avance d'une case.

### Phase 3 : L'Escale
La carte contient 5 Îles isolées et 1 grand Continent connecté le long d'un bord au hasard. Coster sur une de ces entités ouvre la Phase d'Escale.

**L'Île :**
- 5 zones de "butin" pour obtenir divers butins.

**Le Continent :**
- Arriver ici signifie une victoire totale (Fin de la session).
- 15 zones de "butin". 
- Fin d'expédition automatique et conversion des Provisions restantes en Or permanent.

**La Fouille (Le mode de "Grattage") :**
- **Série de caisses :** Boîtes tirées aléatoirement avec de l'Or, des Provisions, du Bois, des Clés, ou des objets rattachés à des Panoplies, ou des Trésors (Mineur ou Majeur).
- **Apparition visuelle :** Parquets de 6 tombant dans une grille de 3x2. Leurs formes suggèrent leur contenu mais doivent être cliquées ou grattées pour que la valeur s'ajoute à la cargaison. Cliquer sur "Go" amène la série suivante.

**La Banque du Capitaine :**
- *Sécuriser* : Convertir "Or en main" en "Pièces d'Or".
- *Se Ravitailler* : Dépenser des "Pièces d'Or Sécurisées" pour payer de nouvelles Provisions.
- *Risquer plus* : Retirer des "Pièces d'Or Sécurisées" en "Or en main" (Optionnel selon Gameplay visé mais indiqué).

**Le Choix Fin d'Escale (sur l'Île) :**
1. *Reprendre la Mer :* Continu l'aventure. Les îles déjà visitées ne peuvent plus être "fouillées" mais simplement servir d'escales bancaires/de ravitaillement.
2. *S'Arrêter :* Fin volontaire (Victoire Partielle). Sécurisation de l'Or en main. **Convertit toutes les Provisions restantes en Pièces d'Or permanentes. Détruit les objets de Panoplies incomplètes et les Clés non exploitées.**

---

## 4. Collection, Panoplies et Clés

Pendant les "grattages", des objets divers et rares peuvent être gagnés et s'accumulent dans la cale.

**4.1 Les Panoplies**
- Les objets des panoplies n'ont de valeur qu'une fois complets (par ex. 3 ou 5 objets dépendamment de la Panoplie).
- Si le joueur revient à terre avec une panoplie complète en cale, l'ensemble est automatiquement validé contre une grande récompense (Or, Provisions ou Jokers).
- Les objets incomplets sont gardés tant que l'expédition continue. Mais si la partie se finit (naufrage ou arrêt volontaire), ces objets sont perdus.

*Exemples de Panoplies :* Le Mariage Noble (3), La Légende du Pirate (5), Le Succès de l'Explorateur (4), etc.

**4.2 Le Trésor Majeur**
- L'objectif principal ultime est de trouver le **Trésor Majeur** et les **3 Clés** pour l'ouvrir (Cuivre, Argent, Or).
- Ces éléments doivent être découverts et combinés durant la **même session**.
- Les clés sont supprimées en fin de partie si elles ne sont pas employées.

---

## 5. Conditions de Fin de Partie (Game Over vs Success)

1. **La Famine ou Naufrage (ÉCHEC)** : Provisions = 0 en pleine mer, ou Percuter un Récif sans Bois de Charpente. Perte sèche de l'Or en Main, des Clés, et du contenu de la Cale.
2. **Arrêt Volontaire sur Île (SUCCÈS PARTIEL)** : Or en main sauvé via la Banque, puis session stoppée. L'or est gardé. Provisions converties en Or Permanent. Contenu de Cale incomplète et clés perdues.
3. **Le Continent (SUCCÈS TOTAL)** : Arriver au bord de la carte. Ultime escale, méga-fouille de la zone de 15 cases. Fin logique de l'Expédition avec validation automatique et conversion des Provisions en Or Permanent.

---

## 6. Choix Technologiques / Architecture Flutter

### 6.1 Framework & Architecture État
- **Framework Global :** Flutter.
- **Cible :** Web (WebGL/CanvasKit pour de bonnes performances visuelles) & Android (Native compilation).
- **State Management :** Utilisation de **Riverpod** (ou Provider) pour gérer :
  - Les ressources : `OrPermanent`, `OrVolatile`, `Provisions`, `Bois`.
  - L'état de Session : "Au Port", "En Navigation", "En Escale Île", "Au Continent", "GameOver".
  - Les objets contenus en soute.

### 6.2 Rendering et Expérience Utilisateur
- **Rendu Matrice / Mer :** Utilisation de `CustomPainter` pour restituer l'océan, les îles environnantes et les mouvements sans bloquer ou surcharger l'arbre des Widget Flutter.
- **Grille de Vision 5x5 :** Le moteur interne calcule via un repère (x,y). Lors de la navigation, le bateau effectue une auto-rotation (0, 90, 180, 270) tandis que les pixels/textures du monde effectuent une simple translation en "sens inverse".
- **Expérience Utilisateur (UX) :** Assurer des transitions visuelles franches (Brouillard plus sombre en mer / Lumière chaude et couleurs vives à l'arrivée sur la plage d'une Île) pour gratifier psychologiquement le joueur du "Soulagement".

### 6.3 Interactions Réseau et Back-End
- **Anti-Cheat :** Logique serveur forte via Firebase (Cloud Functions). La génération de carte 36x36 est côté serveur. Les mouvements du joueur sont des "requêtes de déplacement". Le Backend valide l'action, décrémente les provisions, et répond en révélant la seule case sur laquelle le joueur atterrit : "Mer ?", "Récif ?", "Île ?".
- **Gestion Profil & Authentification :** Utilisation de **Firebase Authentication** pour l'identification des joueurs (connexion par Email/Mot de passe ou via **Google Sign-In**) et **Firestore** pour stocker l'Or sécurisé de façon persistante.
- **Gestion des Droits (Admin & Super Admin) :** 
  - Un **Super Administrateur** est identifié via une variable d'environnement (ex: un email précis forcé dans `APP_ENV` ou `--dart-define=SUPER_ADMIN_EMAIL="..."`).
  - Des **Administrateurs** standards sont identifiés via une collection/un champ dans Firestore. Les autres joueurs sont des utilisateurs normaux.
  - **Menu d'Administration :** Les administrateurs et super administrateurs ont accès à une interface dédiée leur permettant de voir la liste complète des joueurs et de modifier manuellement leur solde de pièces d'or sécurisées.
