// Usage:
//   node scripts/cleanup_duplicate_commodities.js --key ./serviceAccountKey.json --dry-run
//   node scripts/cleanup_duplicate_commodities.js --key ./serviceAccountKey.json
//
// Removes duplicate commodity documents from `commodities` collection.
// Duplicate key: type + commodity + saleMeth + productForm + pricingBasis + unit
// Keeps the newest record by updatedAt/createdAt and deletes the rest.

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { dryRun: false };
  for (let index = 0; index < args.length; index++) {
    if (args[index] === '--key') out.key = args[++index];
    else if (args[index] === '--dry-run') out.dryRun = true;
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

function normalize(value) {
  const raw = String(value ?? '').trim().toLowerCase();
  if (!raw) return '';
  return raw.replace(/\s+/g, ' ');
}

function toDate(value) {
  if (!value) return new Date(0);
  if (value.toDate && typeof value.toDate === 'function') {
    return value.toDate();
  }
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return new Date(0);
}

function keyFor(data) {
  return [
    normalize(data.type),
    normalize(data.commodity),
    normalize(data.saleMeth),
    normalize(data.productForm),
    normalize(data.pricingBasis),
    normalize(data.unit),
  ].join('|');
}

function boolOr(...values) {
  return values.some((value) => value === true);
}

function aggregateFlags(records) {
  return {
    maleRequired: boolOr(...records.map((record) => record.data?.maleRequired)),
    femaleRequired: boolOr(...records.map((record) => record.data?.femaleRequired)),
    totalWeightRequired: boolOr(
      ...records.map((record) => record.data?.totalWeightRequired),
    ),
    totalPriceRequired: boolOr(
      ...records.map((record) => record.data?.totalPriceRequired),
    ),
    expensesRequired: boolOr(...records.map((record) => record.data?.expensesRequired)),
  };
}

async function run() {
  const { key, dryRun } = parseArgs();
  await initAdmin(key);

  const db = admin.firestore();
  const snapshot = await db.collection('commodities').get();
  console.log(`Scanning commodities: ${snapshot.size} document(s)`);

  const keepersByKey = new Map();
  const recordsByKey = new Map();
  const duplicatesToDelete = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const key = keyFor(data);
    const current = {
      id: doc.id,
      ref: doc.ref,
      data,
      ts: toDate(data.updatedAt || data.createdAt),
    };

    const existing = keepersByKey.get(key);
    const grouped = recordsByKey.get(key) ?? [];
    grouped.push(current);
    recordsByKey.set(key, grouped);

    if (!existing) {
      keepersByKey.set(key, current);
      continue;
    }

    if (current.ts > existing.ts) {
      duplicatesToDelete.push(existing);
      keepersByKey.set(key, current);
    } else {
      duplicatesToDelete.push(current);
    }
  }

  if (duplicatesToDelete.length === 0) {
    console.log('No duplicate commodity documents found.');
    process.exit(0);
  }

  const timestamp = new Date().toISOString().replace(/[.:]/g, '-');
  const backupPath = path.resolve(
    'scripts',
    `duplicate_commodities_backup_${timestamp}.json`,
  );
  const backupPayload = duplicatesToDelete.map((record) => ({
    id: record.id,
    data: record.data,
  }));
  fs.writeFileSync(backupPath, JSON.stringify(backupPayload, null, 2));
  console.log(`Backup written: ${backupPath}`);

  if (dryRun) {
    console.log(`[dry-run] Found ${duplicatesToDelete.length} duplicate document(s) to delete:`);
    for (const dup of duplicatesToDelete) {
      const d = dup.data;
      console.log(`- ${dup.id} | ${d.type || ''} | ${d.commodity || ''} | ${d.saleMeth || ''} | ${d.productForm || ''} | ${d.pricingBasis || ''} | ${d.unit || ''}`);
    }
    process.exit(0);
  }

  let batch = db.batch();
  let opCount = 0;
  let deleted = 0;

  // First update keepers with merged requirement flags so behavior is preserved.
  for (const [key, keeper] of keepersByKey.entries()) {
    const grouped = recordsByKey.get(key) ?? [keeper];
    if (grouped.length <= 1) continue;

    const merged = aggregateFlags(grouped);
    batch.update(keeper.ref, {
      maleRequired: merged.maleRequired,
      femaleRequired: merged.femaleRequired,
      totalWeightRequired: merged.totalWeightRequired,
      totalPriceRequired: merged.totalPriceRequired,
      expensesRequired: merged.expensesRequired,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    opCount++;

    if (opCount >= 450) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  for (const dup of duplicatesToDelete) {
    batch.delete(dup.ref);
    opCount++;
    deleted++;

    if (opCount >= 450) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  console.log(`Done. Deleted ${deleted} duplicate commodity document(s).`);
  process.exit(0);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
