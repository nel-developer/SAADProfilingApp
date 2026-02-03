// Usage:
//   node scripts/set_admin.js --email user@example.com --key ./serviceAccountKey.json
// or set GOOGLE_APPLICATION_CREDENTIALS env var and run:
//   node scripts/set_admin.js --email user@example.com

const fs = require('fs');
const admin = require('firebase-admin');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--email') out.email = args[++i];
    else if (args[i] === '--uid') out.uid = args[++i];
    else if (args[i] === '--key') out.key = args[++i];
  }
  return out;
}

async function main() {
  const { email, uid, key } = parseArgs();
  if (!email && !uid) {
    console.error('Provide --email or --uid');
    process.exit(1);
  }

  // Initialize admin SDK
  if (key) {
    const serviceAccount = require(require('path').resolve(key));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } else if (!admin.apps.length) {
    admin.initializeApp();
  }

  try {
    let targetUid = uid;
    if (!targetUid) {
      const user = await admin.auth().getUserByEmail(email);
      targetUid = user.uid;
    }

    // Set custom claim
    await admin.auth().setCustomUserClaims(targetUid, { admin: true });
    console.log(`Custom claim 'admin' set for uid=${targetUid}`);

    // Update Firestore users collection (merge)
    const firestore = admin.firestore();
    await firestore.collection('users').doc(targetUid).set({
      role: 'admin',
      roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`Firestore 'users/${targetUid}' updated with role=admin`);

    // Optionally revoke refresh tokens so new claims are picked up immediately
    await admin.auth().revokeRefreshTokens(targetUid);
    console.log('Revoked refresh tokens for user (they must re-login for claims to refresh).');

    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(2);
  }
}

main();
