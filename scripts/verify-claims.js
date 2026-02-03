// Usage:
// node scripts/verify-claims.js --uid USER_UID
// node scripts/verify-claims.js --email user@example.com

const admin = require('firebase-admin');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--uid') out.uid = args[++i];
    else if (args[i] === '--email') out.email = args[++i];
    else if (args[i] === '--key') out.key = args[++i];
  }
  return out;
}

async function initAdmin(key) {
  if (key) {
    const path = require('path').resolve(key);
    const serviceAccount = require(path);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } else if (!admin.apps.length) {
    admin.initializeApp();
  }
}

async function main() {
  const { uid, email, key } = parseArgs();
  if (!uid && !email) {
    console.error('Provide --uid or --email');
    process.exit(1);
  }

  await initAdmin(key);

  try {
    let user;
    if (uid) user = await admin.auth().getUser(uid);
    else user = await admin.auth().getUserByEmail(email);

    console.log('UID:', user.uid);
    console.log('Email:', user.email);
    console.log('customClaims:', user.customClaims || null);
    process.exit(0);
  } catch (err) {
    console.error('Error fetching user:', err);
    process.exit(2);
  }
}

main();
