// Usage:
//   node scripts/cleanup_legacy_profile_fields.js --key ./serviceAccountKey.json --dry-run
//   node scripts/cleanup_legacy_profile_fields.js --key ./serviceAccountKey.json
//
// Cleans legacy fields from profiling documents in:
//   - profiling_forms
//   - profiling_pending

const admin = require('firebase-admin');

// Fields that must ONLY exist inside recurrenceByYear[year] — not at top-level.
// These were written top-level by older sync code and need to be purged.
const LEGACY_FIELDS = [
  // ── Old broken-down income/remarks (never year-scoped, fully obsolete) ──
  'primaryAmount',
  'primaryRemarks',
  'secondaryAmount',
  'secondaryRemarks',
  'primaryCommodityIncome',
  'primaryCommodityRemarks',
  'secondaryCommodityIncome',
  'secondaryCommodityRemarks',
  'riceIncomeField',
  'riceRemarks',
  'hvcIncomeField',
  'hvcRemarks',
  'livestockIncomeField',
  'livestockRemarks',
  'fishingIncomeField',
  'fishingRemarks',
  'nonFarmFisheriesIncomeField',
  'nonFarmFisheriesRemarks',
  'primaryCommodityRecurrence',
  'primaryCommodityRecurrenceOthers',
  'secondaryCommodityRecurrence',
  'secondaryCommodityRecurrenceOthers',
  'secondaryCommodityOthersRecurrence',

  // ── Commodity fields (now inside year entries only) ──
  'primaryCommodity',
  'primaryCommodityOthers',
  'secondaryCommodity',
  'secondaryCommodityOthers',
  'saadCommodityType',
  'saadCommodities',
  'nonSAADCommodityType',
  'nonSAADCommodities',

  // ── Received commodity (now inside year entries only) ──
  'receivedCommodity',
  'receivedCommodityOthers',
  'receivedPrimaryCommodity',
  'receivedSecondaryCommodity',
  'receivedTotalPrice',
  'receivedExpenses',
  'receivedRemarks',

  // ── Recurrence demographic / farming fields (now inside year entries only) ──
  'maleFamilyMembers',
  'femaleFamilyMembers',
  'yearsInFarming',
  'landTenureship',
  'landTenureshipOthers',

  // ── Monthly income breakdown (now inside year entries only) ──
  'agriRelatedIncome',
  'saadNetIncome',
  'nonSAADNetIncome',
  'nonAgriRelatedIncome',
  'mainSourcesOfIncome',

  // ── Non-farm income: beneficiary / spouse / other members
  //    (now inside year entries only — these are used, just year-scoped) ──
  'beneficiaryNonFarmIncome',
  'beneficiaryRemarks',
  'spouseNonFarmIncome',
  'spouseRemarks',
  'otherMembersNonFarmIncome',
  'otherMembersRemarks',

  // ── Cooperative / organization (now inside year entries only) ──
  'cooperativeName',
  'hasOrganization',
  'cooperativePosition',
  'dateOfMembership',
  'cooperativePositionOthers',

  // ── yearCovered top-level (redundant — years live as keys in recurrenceByYear) ──
  'yearCovered',

  // ── Image paths (local-only, must never be in Firestore) ──
  'idFrontImagePath',
  'idBackImagePath',
  'farmerPhotoPath',
  'signatureImagePath',
  'signatureImageBase64',

  // ── Local folder name (device-only, not needed in Firestore) ──
  'farmerFolderName',

  // ── Flow-only fields (used during profiling session, not needed in DB) ──
  'selectedExistingSaadId',
];

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

async function cleanupCollection(db, collectionName, dryRun) {
  const snapshot = await db.collection(collectionName).get();
  console.log(`Scanning ${collectionName}: ${snapshot.size} document(s)`);

  let changed = 0;
  let updatesPrepared = 0;
  const batches = [];
  let batch = db.batch();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const updates = {};

    for (const field of LEGACY_FIELDS) {
      if (Object.prototype.hasOwnProperty.call(data, field)) {
        updates[field] = admin.firestore.FieldValue.delete();
      }
    }

    if (Object.keys(updates).length === 0) continue;

    changed++;
    if (dryRun) {
      console.log(`[dry-run] ${collectionName}/${doc.id} -> delete keys: ${Object.keys(updates).join(', ')}`);
      continue;
    }

    batch.update(db.collection(collectionName).doc(doc.id), updates);
    updatesPrepared++;

    if (updatesPrepared >= 450) {
      batches.push(batch);
      batch = db.batch();
      updatesPrepared = 0;
    }
  }

  if (!dryRun && updatesPrepared > 0) {
    batches.push(batch);
  }

  if (!dryRun) {
    for (let index = 0; index < batches.length; index++) {
      await batches[index].commit();
      console.log(`Committed ${collectionName} batch ${index + 1}/${batches.length}`);
    }
  }

  console.log(`${collectionName}: ${changed} document(s) ${dryRun ? 'would be' : 'were'} cleaned.`);
  return changed;
}

async function run() {
  const { key, dryRun } = parseArgs();
  await initAdmin(key);

  const db = admin.firestore();
  const collections = ['profiling_forms', 'profiling_pending'];

  let totalChanged = 0;
  for (const collectionName of collections) {
    totalChanged += await cleanupCollection(db, collectionName, dryRun);
  }

  console.log(`Done. ${totalChanged} total document(s) ${dryRun ? 'would be' : 'were'} updated.`);
  process.exit(0);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
