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
**En tant que** joueur, **je veux** pouvoir accoster sur des îles pour fouiller des caisses, **afin de** récolter de l'or volatil et des objets de collection.
- **Critères :** Grattage de caisses en 3x2. Accumulation du butin en soute.

### US.CORE.04 : Banque et Sécurisation
**En tant que** joueur, **je veux** sécuriser mon or volatil dans une banque lors d'une escale, **afin de** ne pas tout perdre en cas de naufrage futur.

### US.CORE.05 : Bois de Charpente (Protection)
**En tant que** joueur, **je veux** collecter du bois, **afin de** m'en servir de protection automatique lors d'une collision avec un récif.

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

### US03 : Exploration du monde (5 Îles)
**En tant que** joueur, **je veux** pouvoir découvrir au moins 5 îles distinctes dans le monde, **afin que** l'exploration soit consistante.
- **Statut :** ✅ Terminé (Carte étendue à 50x50 et génération de 5 îles au lieu de 3).

### US04 : Indices de découverte (Cartes Mystérieuses)
**En tant que** joueur, **je veux** trouver des "cartes mystérieuses" donnant des indices visuels sur la position d'autres îles.
- **Statut :** ✅ Terminé (Loot de cartes et pings visuels sur la bordure de vision).

---

## 3. Fonctionnalités à Venir (Backlog)

### US05 : Diversité thématique des îles
**En tant que** joueur, **je veux** que les îles aient des styles variés (Caraïbes, Nordique, Jungle, etc.) avec des points d'intérêt spécifiques.
- **Statut :** ✅ Terminé (Biomes Tropique, Nordique et Jungle implémentés avec types de cases dédiés, plus POIs : Volcans et Temples).

### US09 : Événements Aléatoires
**En tant que** joueur, **je veux** rencontrer des événements imprévus lors de ma navigation.
- **Statut :** ✅ Terminé (Épaves dérivantes fournissant du bois de charpente ajoutées en mer).

### US10 : Météo Dynamique et Ambiances Visuelles
**En tant que** joueur, **je veux** que l'ambiance visuelle s'adapte à l'environnement.
- **Statut :** ✅ Terminé (Effets de pluie dans la jungle, neige en zone nordique et brume sur l'océan implémentés).

### US11 : Rencontres de Pirates et Système de Combat
**En tant que** joueur, **je veux** affronter des ennemis pour gagner des récompenses ou protéger mes ressources.
- **Statut :** ✅ Terminé (Navires pirates ajoutés sur la carte avec résolution de combat aléatoire impactant les ressources).

### US12 : Système de Progression et Améliorations du Navire
**En tant que** joueur, **je veux** dépenser mon or pour améliorer les capacités de mon navire.
- **Statut :** ✅ Terminé (Atelier Naval implémenté avec niveaux pour la Coque, les Voiles et la Soute).

### US13 : Système de Quêtes et Journal d'Aventure
**En tant que** joueur, **je veux** des objectifs clairs à accomplir pour gagner des récompenses.
- **Statut :** ✅ Terminé (Journal d'aventure implémenté, suivi en temps réel de l'or et de l'exploration).
