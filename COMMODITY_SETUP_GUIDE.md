# 🌾 Commodity Cascading Setup Guide

## Overview

Your app now supports **master commodity data management** with cascading dropdowns:

```
Main Commodity Type (Livestock, Poultry, HVC, Fishing, Rice, Corn)
  ↓
Commodity (Swine, Cattle, Goat, Carabao, Chicken, etc.)
  ↓
Sale Method (Live Animal, Meat Retail, Service, Capture, etc.)
  ↓
Product Form (Weaner, Pork Cuts, Stud, Cull Animal, etc.)
  ↓
Pricing Basis, Unit, Field Requirements (Male/Female/Weight/Expenses)
```

---

## Step 1: Seed Commodity Master Data

Run the Node.js seeding script to populate Firebase with your commodity records:

### Setup

1. **Install Firebase Admin SDK** (if not already installed):
   ```bash
   cd c:\Users\scerh\SAADProfilingApp
   npm install firebase-admin
   ```

2. **Set your Firebase Admin Key**:
   - You should have `da-saad-profiling-firebase-adminsdk-fbsvc-5bf9c6bb42.json` in your project root.
   - In PowerShell, set the environment variable:
     ```powershell
     $env:GOOGLE_APPLICATION_CREDENTIALS = "c:\Users\scerh\SAADProfilingApp\da-saad-profiling-firebase-adminsdk-fbsvc-5bf9c6bb42.json"
     ```

3. **Run the seeding script**:
   ```bash
   node scripts/seed_commodities.js
   ```

   Expected output:
   ```
   🌱 Starting commodity data seeding...
   ✅ Added: Livestock → Swine → Live Animal → Weaner
   ✅ Added: Livestock → Swine → Live Animal → Fattener
   ...
   📊 Seeding complete: 47 added, 0 failed
   ```

---

## Step 2: Test Admin UI

1. **Ensure collection `commodities` exists** in Firestore after seeding.
2. **Open Admin UI** in your Flutter app:
   - Navigate to: Admin → Commodity Management
3. **Test Add Mode**:
   - Click **Add Commodity**
   - Type: `Livestock`
   - Commodity: `Swine`
   - Sale Method: `Live Animal`
   - Product Form: `Weaner`
   - Pricing Basis: `Per Head`
   - Unit: `Head`
   - Check: Male Required, Female Required
   - Click **Save**
4. **Test Edit Mode**:
   - Find the record you just added
   - Click **Edit**
   - Select from dropdowns; note: cascading filters show only valid options
   - Modify a field, click **Save**
5. **Test Delete**:
   - Click the **Trash** icon to delete (optional)

---

## Step 3: Integrate into Profiling Steps

Your profiling form will now use this master data. When a farmer selects:

### Step 4 - Main Commodity (Profiling)

1. **Select Main Commodity Type** (Livestock, Poultry, HVC, Fishing, Rice, Corn)
   - Dropdown filters from `commodities` collection where `type` matches
2. **Select Commodity** (Swine, Cattle, etc.)
   - Dropdown filters where `type` + `commodity` match
3. **Sale Method** auto-loads based on commodity
4. **Product Form** auto-loads based on sale method

### Field Requirements Applied

Based on the selected `ProductForm` record in the `commodities` collection:
- If `male_required: true` → show **Male** input field
- If `female_required: true` → show **Female** input field
- If `total_weight_required: true` → show **Total Weight** field
- If `total_price_required: true` → show **Total Price** field
- If `expenses_required: true` → show **Expenses** field

Example: Farmer selects **Livestock → Swine → Live Animal → Weaner**
- The Weaner record (in commodities) has `male_required: true, female_required: true`
- Profiling form shows: **Male**, **Female** input fields
- Weaner does NOT have `total_weight_required`, so no weight field shown

---

## Commodity Data Schema

Each record in the `commodities` collection contains:

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `id` | String | Auto (Firestore) | Document ID |
| `type` | String | `Livestock` | Master category |
| `commodity` | String | `Swine` | Sub-category |
| `saleMeth` | String | `Live Animal` | Transaction type |
| `productForm` | String | `Weaner` | Product variant |
| `pricingBasis` | String | `Per Head` | How priced |
| `unit` | String | `Head` | Quantity unit |
| `requiresMale` | Boolean | `true` | Show Male field in profiling? |
| `requiresFemale` | Boolean | `true` | Show Female field in profiling? |
| `requiresWeight` | Boolean | `false` | Show Total Weight field? |
| `requiresPrice` | Boolean | `false` | Show Total Price field? |
| `requiresExpenses` | Boolean | `false` | Show Expenses field? |
| `remarks` | String | Optional | Admin notes |
| `createdAt` | Timestamp | Auto | Record created |
| `updatedAt` | Timestamp | Auto | Record last modified |

**Note:** For HVC, Fishing, Rice, Corn: `requiresMale` and `requiresFemale` are `false` (no gender fields).

---

## Admin Features

### Add New Commodity Record
1. Click **Add Commodity** in Admin UI
2. **Type in text fields** (not dropdowns) to create a new master record
3. Fill all required fields (Type, Commodity, Sale Method, Product Form)
4. Check field requirement checkboxes as needed
5. Click **Save**

### Edit Existing Commodity
1. Find record in list
2. Click **Edit**
3. Use cascading dropdowns to navigate to desired record
4. Modify fields
5. Click **Save**

### Delete a Commodity
1. Click the **Trash** icon on a card
2. Record is removed from`commodities` collection

---

## Spreadsheet → Database Mapping

Your spreadsheet data has been mapped as follows:

| Main Commodity | Commodity | Sale Method | Product Form | Male | Female | Notes |
|---|---|---|---|---|---|---|
| Livestock | Swine | Live Animal | Weaner | ✓ | ✓ | Young swine (nursing age) |
| Livestock | Swine | Live Animal | Fattener | ✓ | ✓ | Growing swine |
| Livestock | Swine | Meat Retail | Pork Cuts | – | – | Retail meat pieces |
| Livestock | Cattle | Live Animal | Calf | ✓ | ✓ | Young cattle |
| Livestock | Chicken | Live Animal | Live weight | – | – | Chickens sold alive |
| Poultry | Chicken | Meat Retail | Chicken Cuts | – | – | Butchered chicken pieces |
| HVC | Any Fruits | Fresh Produce | Fresh Fruit | – | – | Fruits (no gender) |
| Fishing | Fish Capture | Capture | Live weight | – | – | Fresh fish caught |
| Fishing | Fish Capture | Post-harvest | Dried Fish | – | – | Dried for storage/sales |
| Rice | Rice | Fresh Produce | Fresh Palay | – | – | Paddy rice (no gender) |
| Corn | Corn | Fresh Produce | Corn | – | – | Corn cobs/kernels (no gender) |

---

## Debugging

### "No commodities found" Error in Edit Mode

**Cause:** The `commodities` collection is empty or has no matching records.

**Solution:**
1. Run seeding script: `node scripts/seed_commodities.js`
2. Verify in Firebase Console: Firestore → Collections → `commodities` (should have ~47 documents)

### Dropdown Shows Empty Options

**Cause:** The selected Type/Commodity/Sale Method has no child records.

**Solution:**
1. In Admin UI, Add a new commodity record with the missing combination
2. Or run seeding script to ensure all master data is present

### Profiling Form Not Showing Field Requirements

**Cause:** The selected ProductForm record has not been saved with the correct `requiresMale`, `requiresFemale` flags.

**Solution:**
1. Go to Admin → Commodity
2. Find the ProductForm record
3. Edit and check the required field checkboxes
4. Click Save

---

## Next: Profiling Integration

Once you've seeded the commodity data and tested the admin UI, update your profiling form steps to use the `CommodityService` for dynamic dropdown loading. See profiling step files for examples of cascading dropdown implementation.

Example usage in profiling:
```dart
// In profiling step, load commodities by type
final commodities = await _commodityService
    .getCommoditiesByCategory(selectedCommodityType);
```

---

### Support

For issues or questions, check:
- Firestore Console → Collections → `commodities` (verify data exists)
- Flutter logs for any CommodityService errors: `flutter run -v | grep Commodity`
