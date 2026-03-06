#!/usr/bin/env node

/**
 * One-time migration:
 * Remove maleCount/femaleCount from SAAD/Non-SAAD commodity entries
 * when those fields are not required for the commodity.
 *
 * Default mode is DRY RUN (no writes).
 *
 * Usage:
 *   node scripts/migrate_remove_sex_counts.js
 *   node scripts/migrate_remove_sex_counts.js --apply
 *   node scripts/migrate_remove_sex_counts.js --apply --key ./serviceAccount.json
 *   node scripts/migrate_remove_sex_counts.js --collection pending
 *   node scripts/migrate_remove_sex_counts.js --collection approved
 *
 * Options:
 *   --apply               Perform writes (without this flag: dry run)
 *   --key <path>          Firebase Admin SDK service account JSON path
 *   --collection <name>   pending | approved | all (default: all)
 */

const admin = require('firebase-admin');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { apply: false, collection: 'all' };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--apply') out.apply = true;
    else if (arg === '--key') out.key = args[++i];
    else if (arg === '--collection') out.collection = (args[++i] || 'all').toLowerCase();
  }

  if (!['all', 'pending', 'approved'].includes(out.collection)) {
    throw new Error('--collection must be one of: all | pending | approved');
  }

  return out;
}

async function initAdmin(keyPath) {
  if (admin.apps.length) return;

  if (keyPath) {
    const path = require('path').resolve(keyPath);
    const serviceAccount = require(path);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    return;
  }

  admin.initializeApp();
}

function normalize(value) {
  return (value ?? '').toString().trim().toLowerCase();
}

function keyForEntry(type, commodity, saleMeth, productForm) {
  return [normalize(type), normalize(commodity), normalize(saleMeth), normalize(productForm)].join('|');
}

function boolOrNull(value) {
  if (value === true) return true;
  if (value === false) return false;
  return null;
}

async function buildCommodityRequirementMap(db) {
  const snapshot = await db.collection('commodities').get();
  const map = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const key = keyForEntry(data.type, data.commodity, data.saleMeth, data.productForm);

    const maleRequired = boolOrNull(data.maleRequired ?? data.requiresMale);
    const femaleRequired = boolOrNull(data.femaleRequired ?? data.requiresFemale);

    if (maleRequired === null && femaleRequired === null) continue;

    map.set(key, {
      maleRequired: maleRequired ?? false,
      femaleRequired: femaleRequired ?? false,
    });
  }

  return map;
}

function isCropLikeEntry(entry) {
  const type = normalize(entry?.type);
  const commodity = normalize(entry?.commodity ?? entry?.commodityName ?? entry?.item);

  if (['rice', 'hvc', 'corn', 'crop', 'crops'].includes(type)) return true;
  if (['rice', 'hvc', 'corn'].includes(commodity)) return true;

  return false;
}

function sanitizeEntries(entries, requirementMap) {
  if (!Array.isArray(entries)) {
    return { entries, changed: false, removedMale: 0, removedFemale: 0 };
  }

  let changed = false;
  let removedMale = 0;
  let removedFemale = 0;

  const updated = entries.map((raw) => {
    const entry = raw && typeof raw === 'object' ? { ...raw } : raw;
    if (!entry || typeof entry !== 'object') return entry;

    const hasMale = Object.prototype.hasOwnProperty.call(entry, 'maleCount');
    const hasFemale = Object.prototype.hasOwnProperty.call(entry, 'femaleCount');
    if (!hasMale && !hasFemale) return entry;

    const key = keyForEntry(entry.type, entry.commodity, entry.saleMeth, entry.productForm);
    const rule = requirementMap.get(key);

    let keepMale;
    let keepFemale;

    if (rule) {
      keepMale = !!rule.maleRequired;
      keepFemale = !!rule.femaleRequired;
    } else if (isCropLikeEntry(entry)) {
      keepMale = false;
      keepFemale = false;
    } else {
      return entry;
    }

    if (!keepMale && hasMale) {
      delete entry.maleCount;
      changed = true;
      removedMale++;
    }

    if (!keepFemale && hasFemale) {
      delete entry.femaleCount;
      changed = true;
      removedFemale++;
    }

    return entry;
  });

  return { entries: updated, changed, removedMale, removedFemale };
}

async function processCollection({ db, collectionName, requirementMap, apply }) {
  const snap = await db.collection(collectionName).get();

  let docsScanned = 0;
  let docsChanged = 0;
  let removedMale = 0;
  let removedFemale = 0;

  let batch = db.batch();
  let batchOps = 0;

  for (const doc of snap.docs) {
    docsScanned++;
    const data = doc.data() || {};

    const saad = sanitizeEntries(data.saadCommodities, requirementMap);
    const nonSaad = sanitizeEntries(data.nonSAADCommodities, requirementMap);

    const hasChanges = saad.changed || nonSaad.changed;
    if (!hasChanges) continue;

    docsChanged++;
    removedMale += saad.removedMale + nonSaad.removedMale;
    removedFemale += saad.removedFemale + nonSaad.removedFemale;

    if (apply) {
      const update = {};
      if (saad.changed) update.saadCommodities = saad.entries;
      if (nonSaad.changed) update.nonSAADCommodities = nonSaad.entries;
      batch.set(doc.ref, update, { merge: true });
      batchOps++;

      if (batchOps >= 400) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }
  }

  if (apply && batchOps > 0) {
    await batch.commit();
  }

  return { docsScanned, docsChanged, removedMale, removedFemale };
}

async function main() {
  const { apply, key, collection } = parseArgs();
  await initAdmin(key);

  const db = admin.firestore();

  console.log(apply ? '🚀 APPLY MODE (writes enabled)' : '🔍 DRY RUN MODE (no writes)');

  const requirementMap = await buildCommodityRequirementMap(db);
  console.log(`📚 Loaded ${requirementMap.size} commodity requirement rule(s).`);

  const targets =
    collection === 'all'
      ? [
          { name: 'profiling_pending', label: 'pending' },
          { name: 'profiling_forms', label: 'approved' },
        ]
      : collection === 'pending'
      ? [{ name: 'profiling_pending', label: 'pending' }]
      : [{ name: 'profiling_forms', label: 'approved' }];

  let totalScanned = 0;
  let totalChanged = 0;
  let totalRemovedMale = 0;
  let totalRemovedFemale = 0;

  for (const target of targets) {
    console.log(`\n➡️ Processing ${target.name} (${target.label})...`);
    const result = await processCollection({
      db,
      collectionName: target.name,
      requirementMap,
      apply,
    });

    totalScanned += result.docsScanned;
    totalChanged += result.docsChanged;
    totalRemovedMale += result.removedMale;
    totalRemovedFemale += result.removedFemale;

    console.log(
      `   scanned=${result.docsScanned}, changed=${result.docsChanged}, removedMale=${result.removedMale}, removedFemale=${result.removedFemale}`,
    );
  }

  console.log('\n✅ Migration summary');
  console.log(`   docsScanned: ${totalScanned}`);
  console.log(`   docsChanged: ${totalChanged}`);
  console.log(`   maleCount removed: ${totalRemovedMale}`);
  console.log(`   femaleCount removed: ${totalRemovedFemale}`);
  console.log(apply ? '   mode: APPLY' : '   mode: DRY RUN');
}

main().catch((err) => {
  console.error('❌ Migration failed:', err.message || err);
  process.exit(1);
});
