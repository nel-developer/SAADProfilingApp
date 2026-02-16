#!/usr/bin/env node

/**
 * seed_commodities.js
 * Populates Firestore 'commodities' collection with master data from the spreadsheet.
 * 
 * Usage:
 *   node scripts/seed_commodities.js
 * 
 * Set GOOGLE_APPLICATION_CREDENTIALS to the path of your Firebase Admin SDK JSON key.
 */

const admin = require('firebase-admin');
const path = require('path');

// Ensure Firebase Admin SDK key is set
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    '❌ Error: GOOGLE_APPLICATION_CREDENTIALS environment variable not set.\n' +
    'Set it to your Firebase Admin SDK JSON key file path.\n' +
    'Example: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// Master commodity data from spreadsheet
const commoditiesData = [
  // LIVESTOCK
  {
    type: 'Livestock',
    commodity: 'Swine',
    saleMeth: 'Live Animal',
    productForm: 'Weaner',
    pricingBasis: 'Per Head',
    unit: 'Head',
    requiresMale: true,
    requiresFemale: true,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Swine',
    saleMeth: 'Live Animal',
    productForm: 'Fattener',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: true,
    requiresFemale: true,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Swine',
    saleMeth: 'Live Animal',
    productForm: 'Cull Animal',
    pricingBasis: 'Per Head',
    unit: 'Head',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Swine',
    saleMeth: 'Meat Retail',
    productForm: 'Pork Cuts',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Swine',
    saleMeth: 'Service',
    productForm: 'Stud',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Cattle',
    saleMeth: 'Live Animal',
    productForm: 'Calf',
    pricingBasis: 'Per Head',
    unit: 'Head',
    requiresMale: true,
    requiresFemale: true,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Cattle',
    saleMeth: 'Live Animal',
    productForm: 'Live weight',
    pricingBasis: 'Per Head',
    unit: 'Head',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Cattle',
    saleMeth: 'Meat Retail',
    productForm: 'Beef Cuts',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Cattle',
    saleMeth: 'Service',
    productForm: 'Stud',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Goat',
    saleMeth: 'Live Animal',
    productForm: 'Kid',
    pricingBasis: 'Per Head',
    unit: 'Head',
    requiresMale: true,
    requiresFemale: true,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Goat',
    saleMeth: 'Live Animal',
    productForm: 'Live weight',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Goat',
    saleMeth: 'Meat Retail',
    productForm: 'Retailed Goat Cuts',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Goat',
    saleMeth: 'Service',
    productForm: 'Stud',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Carabao',
    saleMeth: 'By-product',
    productForm: 'Milk',
    pricingBasis: 'Per Bottle',
    unit: 'Liters',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Carabao',
    saleMeth: 'Live Animal',
    productForm: 'Live weight',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Carabao',
    saleMeth: 'Service',
    productForm: 'Stud',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Livestock',
    commodity: 'Carabao',
    saleMeth: 'Service',
    productForm: 'Draft',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },

  // POULTRY
  {
    type: 'Poultry',
    commodity: 'Chicken',
    saleMeth: 'Live Animal',
    productForm: 'Live weight',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Poultry',
    commodity: 'Chicken',
    saleMeth: 'Meat Retail',
    productForm: 'Chicken Cuts',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Poultry',
    commodity: 'Chicken',
    saleMeth: 'Meat Retail',
    productForm: 'Dressed Chicken',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Poultry',
    commodity: 'Chicken',
    saleMeth: 'By-product',
    productForm: 'Table egg',
    pricingBasis: 'Per Piece',
    unit: 'Pieces',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },

  // HIGH VALUE CROPS
  {
    type: 'High Value Crops',
    commodity: 'Any Fruits',
    saleMeth: 'Fresh Produce',
    productForm: 'Fresh Fruit',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'High Value Crops',
    commodity: 'Any Vegetable',
    saleMeth: 'Fresh Produce',
    productForm: 'Fresh Produce',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'High Value Crops',
    commodity: 'Coconut',
    saleMeth: 'Product',
    productForm: 'Coconut',
    pricingBasis: 'Per Piece',
    unit: 'Pieces',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'High Value Crops',
    commodity: 'Coconut',
    saleMeth: 'By-product',
    productForm: 'Copra',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'High Value Crops',
    commodity: 'Coconut',
    saleMeth: 'Service',
    productForm: 'Copra Processing',
    pricingBasis: 'Per Service',
    unit: 'Service',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },

  // FISHING
  {
    type: 'Fishing',
    commodity: 'Fish Capture',
    saleMeth: 'Capture',
    productForm: 'Live weight',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Fishing',
    commodity: 'Fish Capture',
    saleMeth: 'Post-harvest',
    productForm: 'Dried Fish',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Fishing',
    commodity: 'Fish Capture',
    saleMeth: 'Post-harvest',
    productForm: 'Bottled/Canned Fish',
    pricingBasis: 'Per Piece',
    unit: 'Pieces',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Fishing',
    commodity: 'Aquaculture',
    saleMeth: 'Culture',
    productForm: 'Live weight',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },

  // RICE
  {
    type: 'Rice',
    commodity: 'Rice',
    saleMeth: 'Fresh Produce',
    productForm: 'Fresh Palay',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Rice',
    commodity: 'Rice',
    saleMeth: 'Processed',
    productForm: 'Dried Palay',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
  {
    type: 'Rice',
    commodity: 'Rice',
    saleMeth: 'Milled',
    productForm: 'Rice',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },

  // CORN
  {
    type: 'Corn',
    commodity: 'Corn',
    saleMeth: 'Fresh Produce',
    productForm: 'Corn',
    pricingBasis: 'Per Kilogram',
    unit: 'Kilograms',
    requiresMale: false,
    requiresFemale: false,
    requiresWeight: false,
  },
];

async function seedCommodities() {
  try {
    console.log('🌱 Starting commodity data seeding...\n');

    let successCount = 0;
    let errorCount = 0;

    for (const commodity of commoditiesData) {
      try {
        await db.collection('commodities').add({
          ...commodity,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        successCount++;
        console.log(`✅ Added: ${commodity.type} → ${commodity.commodity} → ${commodity.saleMeth} → ${commodity.productForm}`);
      } catch (err) {
        errorCount++;
        console.error(`❌ Failed to add ${commodity.commodity}:`, err.message);
      }
    }

    console.log(`\n📊 Seeding complete: ${successCount} added, ${errorCount} failed`);
    process.exit(errorCount > 0 ? 1 : 0);
  } catch (err) {
    console.error('❌ Fatal error:', err);
    process.exit(1);
  }
}

seedCommodities();
