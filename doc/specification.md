# Spécification Technique & Documentation : L'Archipel de la Fortune

## 1. Introduction

**L'Archipel de la Fortune** est un jeu d'exploration et de gestion de ressources dont le but est d'explorer un océan généré de manière procédurale pour amasser des richesses et des trésors perdus. Le joueur incarne un Capitaine de navire naviguant à l'ère des grandes découvertes. Chaque expédition est un voyage sans retour possible nécessitant une gestion rigoureuse des vivres (Provisions) et des risques liés à la navigation. Beaucoup de hasard et très peu de stratégie déterminent le succès ou l'échec du joueur. (C'est un jeu de hasard)

Ce document décrit les spécifications techniques et les règles métiers nécessaires pour développer ce jeu à la fois sur le **Web** et sur **Android** en utilisant le framework **Flutter**.

---

## 2. Le Modèle de Jeu et l'Économie

L'économie du jeu repose sur une combinaison de ressources persistantes (conservées entre chaque session : les pièces d'or) et volatiles (tout le reste, lié à la session en cours).

### 2.1 Les Ressources

- **Pièces d'Or Sécurisées (Permanentes) :** Richesse totale du joueur, sauvegardée sur son profil (Firebase/Firestore). Elles sont utilisées pour préparer l'expédition ou acheter des provisions depuis les banques.
- **Or en main (Volatil) :** Richesses récoltées durant l'expédition courante. Elles sont stockées sur le navire et peuvent être perdues en cas de naufrage (Game Over).
- **Les Provisions (🍎) :** Denrées achetables au début et pendant un voyage, ou pouvant être craftées en ramassant des éléments de kit de provisions. Chaque déplacement du navire consomme exactement 1 Provision. Si les provisions tombent à 0 en mer, le navire est perdu (Famine donc Game Over).
- **Le Kit de Réparation (🛠️) :** Ressource volatile servant de "bouclier". À l'impact avec un Récif ou après une défaite face à des pirates, un kit est consommé pour sauver le bateau du naufrage.
- **Les objets de panoplies**
- **Les clés de coffres**

---

## 3. Le Déroulement du Jeu

### Phase 1 : Le Port de Départ

Le jeu commence sur une île sécurisée (Port de Départ) à un endroit aléatoire de la carte.
- **Investissement initial :** Le joueur dépense ses Pièces d'Or pour acheter des Provisions et des Kits de Réparation.
- **Récompense de départ :** Le joueur a droit à un "grattage" gratuit de caisses de ravitaillement pour obtenir un petit bonus (Provisions additionnelles ou Kits de Réparation).

### Phase 2 : En Haute Mer
- **Carte :** Matrice générée de **64x64** cases. Elle est générée de manière procédurale à partir d'une graine (seed).
- **Vision (Limitation) :** Le joueur n'a qu'un aperçu d'une grille **5x5** autour du navire. Le reste est caché (Brouillard de guerre).
- **Cartographie :** Une fonctionnalité de Mini-Carte permet au joueur de visualiser la totalité des 64x64 cases, dévoilant de façon permanente (sans brouillard) toutes les tuiles explorées. Le navire est repositionné sur cette vue.
- **Position d'affichage :** Le navire reste fixe au centre de la vue (lors de la navigation principale). Ce sont les éléments de la carte qui glissent.
- **Les Dangers (Récifs) :** Naviguer sur un récif à 50% de chance de détruire le navire (Game Over) à moins de posséder un Kit de Réparation, il est alors automatiquement consommé si besoin. Ils sont désormais très fréquents (Génération augmentée).

**Mouvements & Navigation relative (Coût : 1 Provision)** :
Aucun retour en arrière n'est permis. Le jeu se joue sur une rotation de 90° :
- **Avancer :** Avance tout droit selon le cap actuel d'une case.
- **Bâbord :** Tourne de -90° puis avance d'une case.
- **Tribord :** Tourne de +90° puis avance d'une case.

### Phase 3 : L'Escale
La carte contient une cinquantaine d'îles isolées et 1 grand Continent connecté le long d'un bord au hasard. Le continent peut s'étendre jusqu'à 12 cases vers le centre de la carte, formant une côte à la forme variée. Accoster sur une de ces entités ouvre la Phase d'Escale. Les tuiles des îles et du continent ne disparaissent plus une fois visitées, elles restent affichées sur la carte du joueur, il n'y a alors plus de butin disponible sur ces tuiles. 

**Le Continent :**
- 15 zones de "butin".
Une fois que le joueur a visité une des cases du continent, toutes les zones de butin du continent sont considérées comme visitées et donc non réutilisables. 

Accoster sur une île ou une case de continent déjà visitée ou pillée permet tout de même d'accéder à la banque du joueur et au ravitaillement. 

**La Fouille (Le mode de "Grattage") :**
- **Série de caisses :** Boîtes tirées aléatoirement. Chaque boîte peut contenir :
  - **Pièces d'or** (2, 5, 10, 25 ou 50, les gros montants étant les plus rares).
  - **Éléments de kit de réparation** (5 éléments nécessaires pour constituer 1 kit complet).
  - **Éléments de kit de provisions** (5 éléments nécessaires pour constituer 1 kit complet offrant 5 Provisions).
  - **Déchets** (Aucune utilité).
  - **Coffre de trésor de cuivre** (Contient 100 pièces d'or). Rare.
  - **Coffre de trésor d'argent** (Contient 250 pièces d'or). Très rare.
  - **Coffre de trésor d'or** (Contient 1000 pièces d'or). Très très rare.
  - **Coffre de trésor majeur** (Contient 2500 pièces d'or). Rarissime.
  - **Clé de cuivre** (Ouvre le coffre de trésor de cuivre). Rare.
  - **Clé d'argent** (Ouvre le coffre de trésor d'argent). Très rare.
  - **Clé d'or** (Ouvre le coffre de trésor d'or). Très très rare.
  - **Cartes mystérieuses** : Révèlent l'emplacement d'une île qui n'est pas encore découverte (elle devient visible sur la mini-carte).
  - **Apparition visuelle :** Paquets de 6 tombant dans une grille de 3x2. 2 paquets à gratter lors d'une escale sur une île (5 pour le Continent). Leur contenu est révélé en interagissant avec, puis l'ensemble du butin crafté est ajouté à votre soute à la fin.
  - les gain des  butins sont consignés dans le journal du capitaine

**La Banque du Capitaine & Marché de Départ:**
- *Sécuriser* : Convertir "Or en main" en "Pièces d'Or".
- *Se Ravitailler (Début)* : Dépenser des "Pièces d'Or Sécurisées" pour acheter de nouvelles Provisions. Formule ajustée : 5 d'Or = 20 Provisions.
- *Achat d'un kit de réparation (Début)* : Dépenser des "Pièces d'Or Sécurisées" pour acheter de nouveaux Kits de Réparation. Formule ajustée : 5 d'Or = 1 Kit de Réparation.
- *Risquer plus* : Retirer des "Pièces d'Or Sécurisées" en "Or en main" (Optionnel).

**Le Choix Fin d'Escale :**
1. *Reprendre la Mer :* Continue l'aventure.
2. *S'Arrêter :* Fin volontaire (Victoire Partielle). Sécurisation de l'Or en main. 

**Conversion :** À la fin de la session, toutes les Provisions restantes sont converties en Pièces d'Or permanentes. Les objets de Panoplies incomplètes et les Clés non exploitées sont détruits.

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
- Les clés sont conservées durant toute la session.
- Les clés sont supprimées en fin de partie si elles ne sont pas employées.
- Les clés peuvent être utilisées pour ouvrir un coffre de trésor de même couleur.

---

## 5. Conditions de Fin de Partie (Game Over vs Success)

1. **La Famine ou Naufrage (ÉCHEC)** : Provisions = 0 en pleine mer, ou percuter un récif sans kit de réparation. Perte sèche de l'Or en Main, des Clés, et du contenu de la Cale.
2. **Arrêt Volontaire sur Île (SUCCÈS PARTIEL)** : Or en main sauvé via la Banque, puis session stoppée. L'or est gardé. Provisions converties en Or Permanent. Contenu de cale incomplet et clés perdus.
3. **Le Continent (SUCCÈS TOTAL)** : Arriver au bord de la carte. Ultime escale, méga-fouille de la zone de 15 cases. Fin logique de l'expédition avec validation automatique et conversion des Provisions en Or Permanent.

---

## 6. Choix Technologiques / Architecture Flutter

### 6.1 Framework & Architecture État
- **Framework Global :** Flutter.
- **Cible :** Web (WebGL/CanvasKit pour de bonnes performances visuelles) & Android (Native compilation).
- **State Management :** Utilisation de **Riverpod** pour gérer :
  - Les ressources : `OrPermanent`, `OrVolatile`, `Provisions`, `Kits de Réparation`, `Clés`, `Panoplies`.
  - L'état de Session : "Au Port", "En Navigation", "En Escale Île", "Au Continent", "GameOver".
  - Les historiques d'événements : Le Journal de bord intégré mémorise divers événements durant le trajet.
  - Les tuiles découvertes : `discoveredTiles` mémorise globalement chaque tuile visitée par la vue 5x5.
  - Les objets contenus en soute.

### 6.2 Rendering et Expérience Utilisateur
- **Rendu Matrice / Mer :** Utilisation de `CustomPainter` pour restituer l'océan, les îles environnantes et les mouvements sans bloquer ou surcharger l'arbre des Widget Flutter.
- **Grille de Vision 5x5 :** Le moteur interne calcule via un repère (x,y). Lors de la navigation, le bateau effectue une auto-rotation (0, 90, 180, 270) tandis que les pixels/textures du monde effectuent une simple translation en "sens inverse".
- **Expérience Utilisateur (UX) :** Assurer des transitions visuelles franches (Brouillard plus sombre en mer / Lumière chaude et couleurs vives à l'arrivée sur la plage d'une Île) pour gratifier psychologiquement le joueur du "Soulagement".

### 6.3 Interactions Réseau et Back-End
- **Anti-Cheat (Allégé) :** Initialement conçu comme une logique serveur forte via Cloud Functions pour chaque mouvement, le système a été simplifié pour améliorer les performances. La génération de carte utilise une graine (seed) partagée. Le client gère les mouvements pour une réactivité optimale, tandis que le serveur valide uniquement les étapes critiques (Escale, Fin de partie, Sécurisation de l'or).
-- **Gestion Profil & Authentification :** Utilisation de **Firebase Authentication** pour l'identification des joueurs (connexion par Email/Mot de passe ou via **Google Sign-In**) et **Firestore** pour stocker l'Or sécurisé de façon persistante.
- **Gestion des Droits (Admin & Super Admin) :** 
  - Un **Super Administrateur** est identifié via une variable d'environnement (ex: un email précis forcé dans `APP_ENV` ou `--dart-define=SUPER_ADMIN_EMAIL="..."`).
  - Des **Administrateurs** standards sont identifiés via une collection/un champ dans Firestore. Les autres joueurs sont des utilisateurs normaux.
  - **Menu d'Administration :** Les administrateurs et super administrateurs ont accès à une interface dédiée leur permettant de voir la liste complète des joueurs et de modifier manuellement leur solde de pièces d'or sécurisées.
