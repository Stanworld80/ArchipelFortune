const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = getFirestore();

// Définir les options globales (Région us-central1 pour correspondre à Cloud Run)
setGlobalOptions({ region: "us-central1" });

// Constantes partagées avec le client
const MAP_SIZE = 64;
const REEF_COUNT = 180;

const TileType = {
  sea: 0,
  shallow: 1,
  reef: 2,
  island: 3,
  continent: 4
};

exports.startExpedition = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Utilisateurs authentifiés uniquement.");

  const { provisions, wood, seed } = request.data;
  const cost = (Math.floor(provisions / 20) * 5) + (wood * 5);

  const userRef = db.collection("users").doc(auth.uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists || userDoc.data().piecesOr < cost) {
    throw new HttpsError("failed-precondition", "Or insuffisant.");
  }

  const actualSeed = seed || Date.now();
  const { map, startX, startY } = generateProceduralMap(actualSeed);

  const sessionRef = db.collection("sessions").doc();
  const sessionData = {
    uid: auth.uid,
    x: startX,
    y: startY,
    orientation: 0,
    provisions: provisions,
    wood: wood,
    orVolatil: 0,
    seed: actualSeed,
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

  return { 
    sessionId: sessionRef.id,
    seed: actualSeed,
    x: startX,
    y: startY
  };
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

  const tileType = session.map[nextX * MAP_SIZE + nextY];
  
  // Voiles Améliorées : Chance de ne pas consommer de provisions (US12)
  // Note: Ici on simplifie en consommant toujours car le backend ne suit pas encore les niveaux d'upgrade
  // TODO: Récupérer les niveaux d'upgrade depuis le document utilisateur
  const nextProvisions = Math.max(0, session.provisions - 1);
  
  let update = {
    x: nextX,
    y: nextY,
    orientation: nextOrientation,
    provisions: nextProvisions,
    statusMessage: ""
  };
  const statusSuffix = "";

  if (nextProvisions <= 0) {
    update.isGameOver = true;
    update.statusMessage = "Famine ! Plus de provisions.";
    update.provisions = 0;
  }

  if (tileType === TileType.reef) {
    if (session.wood > 0) {
      update.wood = FieldValue.increment(-1);
      update.statusMessage = "Collision récif ! -1 Kit Rép.";
    } else {
      update.isGameOver = true;
      update.statusMessage = "Naufrage sur un récif !";
    }
  } else if (tileType === TileType.island) {
    update.isAtStopover = true;
    update.lootRemaining = 2; // 2 paquets
    update.statusMessage = "Escale ! Butin récupéré.";
    

  } else if (tileType === TileType.continent) {
    update.isAtStopover = true;
    update.lootRemaining = 5; // 5 paquets
    update.statusMessage = "Continent atteint ! Objectif final en vue.";
    
    for (let r = 0; r < MAP_SIZE; r++) {
      for (let c = 0; c < MAP_SIZE; c++) {
        if (session.map[r][c] === TileType.continent) {
          session.map[r][c] = TileType.sea;
        }
      }
    }
    update.map = session.map.flat();
  } else {
    update.statusMessage = "Pleine mer...";
  }

  await sessionRef.update(update);

  // Si la partie se termine, on transfère l'or volatil vers l'or permanent de l'utilisateur
  if (update.isGameOver) {
    const finalSessionSnap = await sessionRef.get();
    const finalSession = finalSessionSnap.data();
    const goldToTransfer = finalSession.orVolatil || 0;
    
    if (goldToTransfer > 0) {
      const userRef = db.collection("users").doc(auth.uid);
      await userRef.update({
        piecesOr: FieldValue.increment(goldToTransfer)
      });
    }
  }

  return { success: true };
});

exports.updateSessionLoot = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Auth requise.");

  const { sessionId, gold, wood, provisions } = request.data;
  const sessionRef = db.collection("sessions").doc(sessionId);
  const sessionSnap = await sessionRef.get();

  if (!sessionSnap.exists || sessionSnap.data().uid !== auth.uid) {
    throw new HttpsError("not-found", "Session invalide.");
  }

  const session = sessionSnap.data();
  if (session.isGameOver) throw new HttpsError("failed-precondition", "La partie est déjà terminée.");

  await sessionRef.update({
    orVolatil: FieldValue.increment(gold || 0),
    wood: FieldValue.increment(wood || 0),
    provisions: FieldValue.increment(provisions || 0)
  });

  return { success: true };
});

exports.secureGold = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Auth requise.");

  const { sessionId } = request.data;
  const sessionRef = db.collection("sessions").doc(sessionId);
  const sessionSnap = await sessionRef.get();

  if (!sessionSnap.exists || sessionSnap.data().uid !== auth.uid) {
    throw new HttpsError("not-found", "Session invalide.");
  }

  const session = sessionSnap.data();
  const goldToTransfer = session.orVolatil || 0;

  if (goldToTransfer <= 0) return { success: true, transferred: 0 };

  const userRef = db.collection("users").doc(auth.uid);
  
  await db.runTransaction(async (t) => {
    t.update(userRef, { piecesOr: FieldValue.increment(goldToTransfer) });
    t.update(sessionRef, { orVolatil: 0 });
  });

  return { success: true, transferred: goldToTransfer };
});

// Helper pour simuler le Random déterministe
function generateProceduralMap(seed) {
  const rand = new Random(seed);
  const map = Array(MAP_SIZE).fill(0).map(() => Array(MAP_SIZE).fill(TileType.sea));

  // Position de départ fixe (Centre) pour synchronisation client
  const startX = Math.floor(MAP_SIZE / 2);
  const startY = Math.floor(MAP_SIZE / 2);
  
  // Zone de 5x5 en mer forcée (radius 2)
  for (let i = -2; i <= 2; i++) {
    for (let j = -2; j <= 2; j++) {
      const nx = startX + i;
      const ny = startY + j;
      if (nx >= 0 && nx < MAP_SIZE && ny >= 0 && ny < MAP_SIZE) {
        map[nx][ny] = TileType.sea;
      }
    }
  }

  // Génération des îles (50 îles) avec distance de Manhattan minimale de 3
  const islandCoords = [{ x: startX, y: startY }];
  for (let i = 0; i < 50; i++) {
    let rx, ry;
    let valid = false;
    let attempts = 0;

    while (!valid && attempts < 100) {
      if (i === 0) {
        rx = startX + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 7);
        ry = startY + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 7);
      } else {
        // Au moins 9 cases du bord (index 9 à 54 sur une grille de 64)
        rx = rand.nextInt(MAP_SIZE - 18) + 9;
        ry = rand.nextInt(MAP_SIZE - 18) + 9;
      }

      valid = true;
      // Vérification de la distance de Manhattan minimale de 3 par rapport au départ et aux autres îles
      for (const other of islandCoords) {
        const dist = Math.abs(rx - other.x) + Math.abs(ry - other.y);
        if (dist < 3) {
          valid = false;
          break;
        }
      }

      // Sécurité supplémentaire : s'assurer qu'on ne sort pas des 9 cases de marge
      if (rx < 9 || rx > MAP_SIZE - 10 || ry < 9 || ry > MAP_SIZE - 10) {
        valid = false;
      }

      attempts++;
    }

    if (valid) {
      islandCoords.push({ x: rx, y: ry });
      spawnLand(map, rx, ry, TileType.island, rand);
    }
  }

  // Récifs
  for (let i = 0; i < REEF_COUNT; i++) {
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
  
  // Flattening for easier storage if needed, but keeping as 2D for logic
  return { map, startX, startY }; 
}

function spawnLand(map, x, y, type, rand) {
  map[x][y] = TileType.island;
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
