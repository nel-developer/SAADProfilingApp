// Usage:
//   node scripts/normalize_roles.js --key ./serviceAccountKey.json
// Or set GOOGLE_APPLICATION_CREDENTIALS and run without --key.

const admin = require('firebase-admin');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--key') out.key = args[++i];
    if (args[i] === '--dry-run') out.dryRun = true;
    if (args[i] === '--uid') out.uid = args[++i];
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

function inferRole(data, docId) {
  // Prefer explicit 'role' if present
  if (data.role && typeof data.role === 'string') return data.role;

  // If there is a 'roles' field, try to infer admin flag
  const roles = data.roles;
  if (roles) {
    // If roles is an object with admin:true or contains 'admin' value
    if (typeof roles === 'object') {
      if (roles.admin === true) return 'admin';
      // check values
      const vals = Object.values(roles);
      if (vals.includes('admin')) return 'admin';
      // check keys: some systems store role names as keys
      const keys = Object.keys(roles);
      if (keys.includes('admin')) return 'admin';
    }
    // if roles is a string
    if (typeof roles === 'string' && roles === 'admin') return 'admin';
  }

  // Default to 'user'
  return 'user';
}

async function run() {
  const { key, dryRun = false, uid } = parseArgs();
  await initAdmin(key);
  const db = admin.firestore();

  console.log('Scanning users collection...');
  let query = db.collection('users');
  if (uid) query = query.where(admin.firestore.FieldPath.documentId(), '==', uid);
  const snapshot = await query.get();
  console.log(`Found ${snapshot.size} user document(s)` + (dryRun ? ' (dry-run)' : ''));

  const batches = [];
  let batch = db.batch();
  let opCount = 0;
  const BATCH_LIMIT = 450; // keep under 500

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const inferred = inferRole(data, doc.id);

    const updates = {};
    let needsUpdate = false;

    // ensure 'role' is set and normalized
    if (!data.role || data.role !== inferred) {
      updates.role = inferred;
      updates.roleUpdatedAt = admin.firestore.FieldValue.serverTimestamp();
      needsUpdate = true;
    }

    // remove redundant 'roles' field if present
    if (data.roles !== undefined) {
      updates.roles = admin.firestore.FieldValue.delete();
      needsUpdate = true;
    }

    if (needsUpdate) {
      if (dryRun) {
        console.log(`[dry-run] would update ${doc.id} ->`, updates);
      } else {
        batch.update(db.collection('users').doc(doc.id), updates);
        opCount++;
      }
    }

    if (opCount >= BATCH_LIMIT) {
      batches.push(batch);
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) batches.push(batch);

  if (!dryRun) {
    console.log(`Applying ${batches.length} batch(es)`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`Committed batch ${i + 1}/${batches.length}`);
    }
  } else {
    console.log('Dry-run complete. No changes were written.');
  }

  console.log('Normalization complete.');
  process.exit(0);
}

run().catch(err => { console.error(err); process.exit(1); });
