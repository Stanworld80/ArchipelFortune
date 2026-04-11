DEVOPS : 

j'aimerais que le numéro de version visible sur l'écran de connexion inclus le numéro de build.
De plus, j'aimerais que le numéro de build soit incrémenté à chaque build.  

peut on améliorer les script build_deploy et les github action pour bien prendre en compte "dev" "staging" et "prod" ? 
prendre en compte les possibilité de lancer avec des tests unitaires, test d'intégrations et test e2e , pour dev et staging ? 


User Interface & Gameplay - User Stories

### US01 : Immersion du mouvement (Animation de la mer)
**En tant que** joueur, **je veux** voir une animation de la mer défilant sous mon bateau lors de mes déplacements, **afin de** renforcer le sentiment de navigation et l'immersion visuelle.

### US02 : Géographie des îles et transitions côtières
**En tant que** joueur, **je veux** que les îles soient composées d'une case centrale (terre) entourée de plages, de ports et d'eaux peu profondes (turquoise), **afin de** créer une transition naturelle vers l'eau profonde du large et rendre la carte visuellement riche.

### US03 : Exploration du monde (5 Iles)
**En tant que** joueur, **je veux** pouvoir découvrir au moins 5 îles distinctes dans le monde, **afin que** l'exploration soit consistante et gratifiante. 
*Note : Nécessite possiblement une révision de la dimension totale de la carte.*

### US04 : Indices de découverte (Cartes Mystérieuses)
**En tant que** joueur, **je veux** pouvoir trouver des "cartes mystérieuses" sur certaines îles, **afin d'**obtenir un indice visuel (dessin du trajet) m'indiquant la position relative d'une autre île.

### US05 : Diversité thématique des îles
**En tant que** joueur, **je veux** que les îles générées aient des styles variés et aléatoires (Anglaise, Asiatique, Désert, Jungle, Caraïbes, Rocheuse, Sauvage), **afin que** chaque découverte soit unique. Chaque île doit contenir au moins un point d'intérêt : port, village, campement ou cité.

### US06 : Le Continent (Objectif Final)
**En tant que** joueur, **je veux** récupérer le butin sur un continent (composé de plusieurs cases) comme objectif ; il ne sera plus possible de récupérer le butin de continent même en allant sur une autre case du continent.

### US07 : Dangers maritimes (Récifs)
**En tant que** joueur, **je veux** rencontrer des cases "Récifs" présentant un risque de 50% d'endommager le bateau, **afin de** devoir gérer mes ressources (bois de réparation) sous peine de naufrage.

### US08 : Collecte de ressources (Mini-jeu de Pêche)
**En tant que** joueur, **je veux** participer à un mini-jeu de pêche sur des cases dédiées, où je voit un filet oscillant soumis aux courants pour remonter du butin (objets rares/communs), **afin de** rendre la collecte de ressources visuelle et basée sur la chance. le joueur peut remonter un objet 'filet de pêche suplémentaire" ce qui lui donne droit a un second lancer de filet.
