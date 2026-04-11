const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = getFirestore();

// Définir les options globales (Région us-central1 pour correspondre à Cloud Run)
setGlobalOptions({ region: "us-central1" });

// Constantes partagées avec le client
const MAP_SIZE = 50;

const TileType = {
  sea: 0,
  shallow: 1,
  sand: 2,
  grass: 3,
  forest: 4,
  reef: 5,
  island: 6,
  continent: 7,
  port: 8,
  fishing: 9,
  snow: 10,
  ice: 11,
  jungle: 12,
  swamp: 13,
  temple: 14,
  volcano: 15,
  shipwreck: 16,
  pirate: 17
};

exports.startExpedition = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Utilisateurs authentifiés uniquement.");

  const { provisions, wood, seed } = request.data;
  const cost = (Math.floor(provisions / 10) * 5) + (wood * 10);

  const userRef = db.collection("users").doc(auth.uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists || userDoc.data().piecesOr < cost) {
    throw new HttpsError("failed-precondition", "Or insuffisant.");
  }

  // Génération de la carte (simplifiée pour le stockage)
  const map = generateProceduralMap(seed || Date.now());

  const sessionRef = db.collection("sessions").doc();
  const sessionData = {
    uid: auth.uid,
    x: Math.floor(MAP_SIZE / 2),
    y: Math.floor(MAP_SIZE / 2),
    orientation: 0,
    provisions: provisions,
    wood: wood,
    orVolatil: 0,
    seed: seed || Date.now(),
    map: map.flat(),
    inventory: [],
    collections: {},
    isAtStopover: false,
    lootRemaining: 0,
    startTime: FieldValue.serverTimestamp(),
    isGameOver: false,
    statusMessage: "Expédition lancée !"
  };

  await db.runTransaction(async (t) => {
    t.update(userRef, { piecesOr: FieldValue.increment(-cost) });
    t.set(sessionRef, sessionData);
  });

  return { sessionId: sessionRef.id };
});

exports.moveShip = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Auth requise.");

  const { sessionId, direction } = request.data;
  const sessionRef = db.collection("sessions").doc(sessionId);
  const sessionSnap = await sessionRef.get();

  if (!sessionSnap.exists || sessionSnap.data().uid !== auth.uid) {
    throw new HttpsError("not-found", "Session invalide.");
  }

  const session = sessionSnap.data();
  if (session.isGameOver) return { error: "Partie terminée." };

  if (session.provisions <= 0) {
    await sessionRef.update({ isGameOver: true, statusMessage: "Famine !" });
    return { isGameOver: true };
  }

  let nextX = session.x;
  let nextY = session.y;
  let nextOrientation = session.orientation;

  if (direction === "forward") {
    // Reste sur la même orientation
  } else if (direction === "port") {
    nextOrientation = (nextOrientation - 90 + 360) % 360;
  } else if (direction === "starboard") {
    nextOrientation = (nextOrientation + 90) % 360;
  }

  if (nextOrientation === 0) nextY--;
  else if (nextOrientation === 90) nextX++;
  else if (nextOrientation === 180) nextY++;
  else if (nextOrientation === 270) nextX--;

  // Validation des limites (Mur infranchissable)
  if (nextX < 0 || nextX >= MAP_SIZE || nextY < 0 || nextY >= MAP_SIZE) {
    // On annule juste le mouvement, pas de provision consommée, pas de Game Over
    await sessionRef.update({ statusMessage: "Mur infranchissable !" });
    return { success: false, reason: "out_of_bounds" };
  }

  const tileType = session.map[nextX][nextY];
  let update = {
    x: nextX,
    y: nextY,
    orientation: nextOrientation,
    provisions: FieldValue.increment(-1),
    statusMessage: ""
  };

  if (tileType === TileType.reef) {
    if (session.wood > 0) {
      update.wood = FieldValue.increment(-1);
      update.statusMessage = "Collision avec un récif ! Réparations effectuées.";
    } else {
      update.isGameOver = true;
      update.statusMessage = "Naufrage sur un récif !";
    }
  } else if (tileType === TileType.island || tileType === TileType.port) {
    update.isAtStopover = true;
    update.lootRemaining = 5;
    update.statusMessage = "Escale ! Butin récupéré.";
    
    session.map[nextX][nextY] = TileType.grass;
    update.map = session.map.flat();
  } else if (tileType === TileType.continent) {
    update.isAtStopover = true;
    update.lootRemaining = 15;
    update.statusMessage = "Continent atteint ! Objectif final en vue.";
    
    // US06: Rendre tout le continent inexploitable après le premier loot
    for (let r = 0; r < MAP_SIZE; r++) {
      for (let c = 0; c < MAP_SIZE; c++) {
        if (session.map[r][c] === TileType.continent) {
          session.map[r][c] = TileType.grass;
        }
      }
    }
    update.map = session.map.flat();
  } else if (tileType === TileType.fishing) {
    update.isAtStopover = true;
    update.lootRemaining = 1; // Un seul lancer de filet par défaut
    update.statusMessage = "C'est l'heure de pêcher !";
    
    // On ne retire pas forcément le spot de pêche, ou on le transforme en mer
    session.map[nextX][nextY] = TileType.sea;
    update.map = session.map.flat();
  }

  await sessionRef.update(update);
  return { success: true };
});

// Helper pour simuler le Random déterministe
function generateProceduralMap(seed) {
  const rand = new Random(seed);
  const map = Array(MAP_SIZE).fill(0).map(() => Array(MAP_SIZE).fill(TileType.sea));

  // Position de départ forcée en MER
  const startX = Math.floor(MAP_SIZE / 2);
  const startY = Math.floor(MAP_SIZE / 2);
  map[startX][startY] = TileType.sea;

  // Génération des îles (5 îles)
  for (let i = 0; i < 5; i++) {
    let rx, ry;
    if (i === 0) {
      rx = startX + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
      ry = startY + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
    } else {
      rx = rand.nextInt(MAP_SIZE - 10) + 5;
      ry = rand.nextInt(MAP_SIZE - 10) + 5;
    }
    
    if (Math.abs(rx - startX) < 2 && Math.abs(ry - startY) < 2) continue;
    
    // US05: Attribution d'un biome (0: Tropical, 1: Nordique, 2: Jungle)
    const biome = rand.nextInt(3);
    spawnLand(map, rx, ry, TileType.island, biome, rand);
  }

  // Récifs
  for (let i = 0; i < 20; i++) {
    const rx = rand.nextInt(MAP_SIZE);
    const ry = rand.nextInt(MAP_SIZE);
    if (map[rx][ry] === TileType.sea) map[rx][ry] = TileType.reef;
  }

  // Continent
  const edge = rand.nextInt(4);
  for (let i = 0; i < MAP_SIZE; i++) {
    if (edge === 0) applyContinent(map, i, 0);
    else if (edge === 1) applyContinent(map, i, MAP_SIZE - 1);
    else if (edge === 2) applyContinent(map, 0, i);
    else if (edge === 3) applyContinent(map, MAP_SIZE - 1, i);
  }
  
  // Spots de pêche (15 spots aléatoires en mer)
  for (let i = 0; i < 15; i++) {
    const rx = rand.nextInt(MAP_SIZE);
    const ry = rand.nextInt(MAP_SIZE);
    if (map[rx][ry] === TileType.sea) map[rx][ry] = TileType.fishing;
  }

  // Épaves dérivantes (10 spots aléatoires en mer)
  for (let i = 0; i < 10; i++) {
    const rx = rand.nextInt(MAP_SIZE);
    const ry = rand.nextInt(MAP_SIZE);
    if (map[rx][ry] === TileType.sea) map[rx][ry] = TileType.shipwreck;
  }

  // Navires pirates (8 spots aléatoires en mer)
  for (let i = 0; i < 8; i++) {
    const rx = rand.nextInt(MAP_SIZE);
    const ry = rand.nextInt(MAP_SIZE);
    if (map[rx][ry] === TileType.sea) map[rx][ry] = TileType.pirate;
  }

  // Flattening for easier storage if needed, but keeping as 2D for logic
  return map; 
}

function spawnLand(map, x, y, type, biome, rand) {
  const radius = 3;
  let portPlaced = false;

  // Définition des types selon le biome
  let centerTile = type;
  let beachTile = TileType.sand;
  let extraTile = TileType.forest; // Par défaut jungle ou forêt

  if (biome === 1) { // Nordique
    centerTile = TileType.snow;
    beachTile = TileType.ice;
    extraTile = TileType.snow;
  } else if (biome === 2) { // Jungle
    centerTile = TileType.jungle;
    beachTile = TileType.swamp;
    extraTile = TileType.jungle;
  }

  for (let i = -radius; i <= radius; i++) {
    for (let j = -radius; j <= radius; j++) {
      const nx = x + i;
      const ny = y + j;
      if (nx < 0 || nx >= MAP_SIZE || ny < 0 || ny >= MAP_SIZE) continue;

      const dist = Math.sqrt(i * i + j * j);
      
      // Centre de l'île / Forêt dense
      if (dist < 1.2) {
        // Chance de POI au centre (Volcan pour Tropical)
        if (biome === 0 && rand.next() > 0.85) {
          map[nx][ny] = TileType.volcano;
        } else {
          map[nx][ny] = centerTile;
        }
      } 
      else if (dist < 1.8) {
        // Placement d'UN port unique
        if (!portPlaced && rand.next() > 0.6) {
          map[nx][ny] = TileType.port;
          portPlaced = true;
        } else {
          // Chance de Temple dans la jungle ou forêt
          if ((biome === 2 || biome === 0) && rand.next() > 0.9) {
            map[nx][ny] = TileType.temple;
          } else {
            map[nx][ny] = extraTile;
          }
        }
      }
      // Plages / Transition
      else if (dist < 2.5) {
        if (map[nx][ny] === TileType.sea) map[nx][ny] = beachTile;
      }
      // Eaux peu profondes (Shallow)
      else if (dist < 3.2) {
        if (map[nx][ny] === TileType.sea) map[nx][ny] = TileType.shallow;
      }
    }
  }

  // Sécurité: Si aucun port n'a été placé par probabilité, on en force un
  if (!portPlaced) {
    const nx = x + 1;
    const ny = y;
    if (nx >= 0 && nx < MAP_SIZE && ny >= 0 && ny < MAP_SIZE) {
      map[nx][ny] = TileType.port;
    }
  }
}

function applyContinent(map, x, y) {
  map[x][y] = TileType.continent;
  for (let i = -1; i <= 1; i++) {
    for (let j = -1; j <= 1; j++) {
      const nx = x + i;
      const ny = y + j;
      if (nx >= 0 && nx < MAP_SIZE && ny >= 0 && ny < MAP_SIZE) {
        if (map[nx][ny] === TileType.sea) map[nx][ny] = TileType.shallow;
      }
    }
  }
}

// Classe Random minimaliste pour le déterminisme (LGC)
class Random {
  constructor(seed) {
    this.seed = seed;
  }
  next() {
    this.seed = (this.seed * 16807) % 2147483647;
    return this.seed / 2147483647;
  }
  nextInt(max) {
    return Math.floor(this.next() * max);
  }
  nextBool() {
    return this.next() > 0.5;
  }
}
