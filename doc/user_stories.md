# Documentation des User Stories : Archipel de la Fortune

Ce document centralise l'ensemble des fonctionnalités du jeu sous forme de User Stories (US), classées par état d'avancement.

## 1. Fonctionnalités de Base (Implémentées)

### US.CORE.01 : Navigation Relative
**En tant que** joueur, **je veux** piloter mon navire via des commandes relatives (Avancer, Bâbord, Tribord), **afin de** naviguer dans l'archipel de manière thématique.
- **Critères :** Chaque mouvement coûte 1 Provision. Rotation de 90°.

### US.CORE.02 : Gestion des Provisions (Famine)
**En tant que** joueur, **je veux** que mes provisions diminuent à chaque action, **afin d'**avoir un défi de gestion.
- **Critères :** Si Provisions = 0, la session se termine par un échec (Famine).

### US.CORE.03 : Escales et Fouille
**En tant que** joueur, **je veux** pouvoir accoster sur des îles pour fouiller des caisses, **afin de** récolter de l'or volatil, des cartes mystérieuses et des outils de survie.
- **Critères :** Grattage de caisses en 3x2 (2 paquets par défaut). Les pépites s'accumulent. Les fragments de kits s'assemblent par 5 pour former des kits complets.

### US.CORE.04 : Banque et Sécurisation
**En tant que** joueur, **je veux** sécuriser mon or volatil dans une banque lors d'une escale, **afin de** ne pas tout perdre en cas de naufrage futur.

### US.CORE.05 : Kits de Réparation (Protection)
**En tant que** joueur, **je veux** collecter des kits de réparation (directement ou via fragments), **afin de** m'en servir de protection automatique lors d'une collision avec un récif ou suite à une défaite navale.

---

## 2. Améliorations Récentes (Implémentées)

### US01 : Immersion du mouvement (Animation de la mer)
**En tant que** joueur, **je veux** voir une animation de la mer défilant sous mon bateau lors de mes déplacements, **afin de** renforcer le sentiment de navigation et l'immersion visuelle.
- **Statut :** ✅ Terminé (Animation shader-like via CustomPainter).

### US02 : Géographie des îles et transitions côtières
**En tant que** joueur, **je veux** que les îles soient composées d'une case centrale (terre) entourée de plages, de ports et d'eaux peu profondes (turquoise), **afin de** créer une transition naturelle vers l'eau profonde du large.
- **Statut :** ✅ Terminé (Algorithme de génération circulaire par calques).

### US06 : Le Continent (Objectif Final)
**En tant que** joueur, **je veux** récupérer le butin sur un continent (composé de plusieurs cases) comme objectif ; il ne sera plus possible de récupérer le butin de continent même en allant sur une autre case du continent.
- **Statut :** ✅ Terminé (Règle du point de non-retour implémentée).

### US07 : Dangers maritimes (Récifs)
**En tant que** joueur, **je veux** que les récifs aient 50% de chance d'endommager le bois ou de couler le navire.
- **Statut :** ✅ Terminé (Probabilité de collision ajoutée).

### US08 : Mini-jeu de Pêche
**En tant que** joueur, **je veux** participer à un mini-jeu de pêche avec un filet oscillant pour remonter des trésors ou des objets bonus.
- **Statut :** ✅ Terminé (FishingOverlay oscillant et butin aléatoire).

### US03 : Exploration du monde (9 Îles)
**En tant que** joueur, **je veux** pouvoir découvrir au moins 9 îles distinctes dans le monde de grande taille, **afin que** l'exploration soit consistante.
- **Statut :** ✅ Terminé (Carte étendue à 64x64 et génération de 9 îles au lieu de 5).

### US04 : Indices de découverte (Cartes Mystérieuses)
**En tant que** joueur, **je veux** trouver des "cartes mystérieuses" donnant des indices visuels sur la position d'autres îles.
- **Statut :** ❌ Retiré (Le jeu a été simplifié et ce mécanisme visuel a été retiré, favorisant la Mini-Carte intégrée).

---

## 3. Fonctionnalités Simplifiées (Retirées du périmètre)

### US05 : Diversité thématique des îles
**Statut :** ❌ Retiré (Reste limité à 5 types de terrain de base standard).

### US09 : Événements Aléatoires
**Statut :** ❌ Retiré.

### US10 : Météo Dynamique et Ambiances Visuelles
**Statut :** ❌ Retiré.

### US11 : Rencontres de Pirates et Système de Combat
**Statut :** ❌ Retiré.

### US12 : Système de Progression et Améliorations du Navire
**Statut :** ❌ Retiré (Seulement base UI).

### US13 : Système de Quêtes
**Statut :** ❌ Retiré.

---

## 4. Nouvelles Fonctionnalités Récentes

### US14 : Mini-Carte et Brouillard de Guerre Exploratoire
**En tant que** joueur, **je veux** pouvoir ouvrir une mini-carte montrant la grille intégrale 64x64 gardant en mémoire toutes les tuiles que mon navire a explorées, **afin de** me repérer précisément.
- **Statut :** ✅ Terminé (Sauvegarde des tuiles découvertes dans `SessionState` et affichage Modale).

### US15 : Journal de Bord d'Expédition
**En tant que** joueur, **je veux** consulter un journal de bord listant l'historique de l'expédition actuelle, **afin de** comprendre l'évolution du voyage et les découvertes.
- **Statut :** ✅ Terminé (Journal UI et Logging implémentés au niveau du SessionNotifier).

### US16 : Économie de Préparation Réajustée
**En tant que** joueur, **je veux** que les coûts et dotations par défaut encouragent un meilleur départ sans ruiner la trésorerie.
- **Statut :** ✅ Terminé (5 Or = 20 Provisions, Départ avec 2 kits de charpente suggérés).

