const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

// Initialize with application default credentials (works if logged in via firebase login)
admin.initializeApp({
  projectId: 'archipel-fortune-dev'
});

const db = admin.firestore();

async function elevateUser(email) {
  try {
    const userSnapshot = await db.collection('users').where('email', '==', email).get();
    
    if (userSnapshot.empty) {
      console.log('No user found with email:', email);
      return;
    }

    const userDoc = userSnapshot.docs[0];
    const uid = userDoc.id;

    await db.collection('users').doc(uid).update({
      role: 'superAdmin'
    });

    console.log(`Successfully elevated user ${email} (${uid}) to superAdmin.`);
  } catch (error) {
    logger.error('Error elevating user:', error);
    process.exit(1);
  }
}

const targetEmail = 'stantest@stanworld.org';
elevateUser(targetEmail);
