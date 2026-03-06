const admin = require('firebase-admin');
const path = require('path');

// Service account JSON (make sure this file exists in project root)
const serviceAccountPath = path.join(__dirname, '..', 'da-saad-profiling-firebase-adminsdk-fbsvc-5bf9c6bb42.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Commodity rows extracted from the image (master fields only)
const rows = [
  { type: 'Livestock', commodity: 'Swine', saleMeth: 'Live Animal', productForm: 'Weaner', pricingBasis: 'Per Head', unit: 'Head' },
  { type: 'Livestock', commodity: 'Swine', saleMeth: 'Live Animal', productForm: 'Fattener', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Swine', saleMeth: 'Live Animal', productForm: 'Cull Animal', pricingBasis: 'Per Head', unit: 'Head' },
  { type: 'Livestock', commodity: 'Swine', saleMeth: 'Meat Retail', productForm: 'Pork Cuts', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Swine', saleMeth: 'Service', productForm: 'Stud', pricingBasis: 'Per Service', unit: 'Service' },

  { type: 'Livestock', commodity: 'Cattle', saleMeth: 'Live Animal', productForm: 'Calf', pricingBasis: 'Per Head', unit: 'Head' },
  { type: 'Livestock', commodity: 'Cattle', saleMeth: 'Live Animal', productForm: 'Live weight', pricingBasis: 'Per Head', unit: 'Head' },
  { type: 'Livestock', commodity: 'Cattle', saleMeth: 'Meat Retail', productForm: 'Beef Cuts', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Cattle', saleMeth: 'Service', productForm: 'Stud', pricingBasis: 'Per Service', unit: 'Service' },

  { type: 'Livestock', commodity: 'Goat', saleMeth: 'Live Animal', productForm: 'Kid', pricingBasis: 'Per Head', unit: 'Head' },
  { type: 'Livestock', commodity: 'Goat', saleMeth: 'Live Animal', productForm: 'Live weight', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Goat', saleMeth: 'Meat Retail', productForm: 'Retailed Goat Cuts', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Goat', saleMeth: 'Service', productForm: 'Stud', pricingBasis: 'Per Service', unit: 'Service' },

  { type: 'Livestock', commodity: 'Carabao', saleMeth: 'By-product', productForm: 'Milk', pricingBasis: 'Bottle', unit: 'Litters' },
  { type: 'Livestock', commodity: 'Carabao', saleMeth: 'Live Animal', productForm: 'Live weight', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Livestock', commodity: 'Carabao', saleMeth: 'Service', productForm: 'Stud', pricingBasis: 'Per Service', unit: 'Service' },
  { type: 'Livestock', commodity: 'Carabao', saleMeth: 'Service', productForm: 'Draft', pricingBasis: 'Per Service', unit: 'Service' },

  { type: 'Poultry', commodity: 'Chicken', saleMeth: 'Live Animal', productForm: 'Live weight', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Poultry', commodity: 'Chicken', saleMeth: 'Meat Retail', productForm: 'Chicken Cuts', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Poultry', commodity: 'Chicken', saleMeth: 'Meat Retail', productForm: 'Dressed Chicken', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Poultry', commodity: 'Chicken', saleMeth: 'By-product', productForm: 'Table egg', pricingBasis: 'Per Piece', unit: 'Pieces' },

  { type: 'High Value Crops', commodity: 'Any Fruits', saleMeth: 'Fresh Produce', productForm: 'Fresh Fruit', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'High Value Crops', commodity: 'Any Vegetable', saleMeth: 'Fresh Produce', productForm: 'Fresh Produce', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'High Value Crops', commodity: 'Coconut', saleMeth: 'Product', productForm: 'Coconut', pricingBasis: 'Per Piece', unit: 'Pieces' },
  { type: 'High Value Crops', commodity: 'Coconut', saleMeth: 'By-product', productForm: 'Copra', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'High Value Crops', commodity: 'Coconut', saleMeth: 'Service', productForm: 'Copra Processing', pricingBasis: 'Per Service', unit: 'Service' },

  { type: 'Fishing', commodity: 'Fish Capture', saleMeth: 'Capture', productForm: 'Live weight', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Fishing', commodity: 'Fishing', saleMeth: 'Post-harvest', productForm: 'Dried Fish', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Fishing', commodity: 'Fishing', saleMeth: 'Post-harvest', productForm: 'Bottled/Canned Fish', pricingBasis: 'Per Piece', unit: 'Pieces' },
  { type: 'Fishing', commodity: 'Aquaculture', saleMeth: 'Culture', productForm: 'Live weight', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },

  { type: 'Rice', commodity: 'Rice', saleMeth: 'Fresh Produce', productForm: 'Fresh Palay', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Rice', commodity: 'Rice', saleMeth: 'Processed', productForm: 'Dried Palay', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
  { type: 'Rice', commodity: 'Rice', saleMeth: 'Milled', productForm: 'Rice', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },

  { type: 'Corn', commodity: 'Corn', saleMeth: 'Fresh Produce', productForm: 'Corn', pricingBasis: 'Per Kilogram', unit: 'Kilograms' },
];

async function runImport() {
  let imported = 0;
  let failed = 0;

  for (const row of rows) {
    const doc = Object.assign({}, row, { createdAt: new Date(), updatedAt: new Date() });
    try {
      await db.collection('commodities').add(doc);
      imported++;
      console.log('Imported:', row.type, row.commodity, row.saleMeth, row.productForm);
    } catch (e) {
      failed++;
      console.error('Failed importing row:', row, e);
    }
  }

  console.log(`\nImport finished. Imported: ${imported}, Failed: ${failed}`);
  // Write a result file for tooling to read
  const fs = require('fs');
  try {
    fs.writeFileSync(path.join(__dirname, 'import_result.json'), JSON.stringify({ imported, failed }, null, 2));
  } catch (e) {
    console.error('Failed writing result file', e);
  }
}

runImport().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
