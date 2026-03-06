# Batch Commodity Entry Feature

## Overview
Enhanced the Admin Commodity Modal to allow adding **multiple product forms** for the same Type → Commodity → Sale Method combination in a single form session, without reopening the modal each time.

## Problem Solved
Previously, users had to:
1. Select Type → Commodity → Sale Method → Product Form
2. Fill pricing basis and unit
3. Click Save
4. Reopen the modal to add another product form for the same Type/Commodity/Sale Method

Now they can:
1. Select Type → Commodity → Sale Method
2. Add multiple product forms for that combination
3. Save all at once

## How It Works

### User Workflow
1. **Setup Base Combination**: Select Commodity Type (e.g., "Livestock") → Commodity (e.g., "Duck") → Sale Method (e.g., "Live Animal")
2. **Add Product Forms**: 
   - Select Product Form (e.g., "Adult Bird")
   - Set Pricing Basis (e.g., "Per Head")
   - Set Unit (e.g., "Pieces")
   - Click **"+ Add to List"** button
3. **Repeat**: Select next Product Form (e.g., "Duckling") and click "+ Add to List" again
4. **Review**: See all added product forms in the green list box
5. **Save All**: Click **"Save All (n)"** button to save all product forms at once

## Technical Implementation

### New State Variables
- `List<CommodityData> _addedProductForms = []` — Tracks all product forms added during this session

### New Methods
- `_addProductFormToList()` — Validates current selection and adds to list
  - Builds `CommodityData` from current form state
  - Validates all required fields
  - Adds to `_addedProductForms` list
  - Resets product form selection, pricing basis, and unit fields
  - Keeps Type, Commodity, and Sale Method selected for next entry
  
- `_saveAllProductForms()` — Saves all accumulated entries
  - Retrieves all items from `_addedProductForms`
  - Calls `widget.onSave()` for each item
  - Updates Firestore and LocalCommodityCache automatically

### UI Changes
1. **Added Product Forms List** (appears when items added):
   - Green container showing all added items
   - Each item displays: Product Form, Pricing Basis, Unit
   - Delete (X) button to remove individual items
   - Count badge: "Added Product Forms (3)"

2. **New Action Buttons**:
   - **"+ Add to List"** (Blue) — Only shows when Product Form is selected
     - Adds current selection to the list without closing modal
   - **"Save All (n)"** (Green) — Only shows when items are in list
     - Saves all n product forms to database
     - Replaces old "Save" button during batch entry

3. **Edit Mode**:
   - When editing existing commodity, it's pre-added to the list
   - Users can add more product forms or remove it

### Data Flow
```
Type selected → loads commodities for type
  ↓
Commodity selected → loads sale methods for commodity
  ↓
Sale Method selected → loads product forms for sale method
  ↓
Product Form selected → "+ Add to List" button enabled
  ↓
Click "+ Add to List" → adds to _addedProductForms, resets fields
  ↓
Repeat as needed
  ↓
Click "Save All" → saves each item to Firestore
  ↓
LocalCommodityCache updated automatically
```

## Example Usage

**Scenario**: Add 3 product forms for Livestock → Duck → Live Animal

1. Select Type: **Livestock**
2. Select Commodity: **Duck**
3. Select Sale Method: **Live Animal**
4. Select Product Form: **Adult Bird**, Pricing Basis: **Per Head**, Unit: **Pieces**
   - Click "+ Add to List"
5. Select Product Form: **Duckling**, Pricing Basis: **Per Head**, Unit: **Pieces**
   - Click "+ Add to List"
6. Select Product Form: **Whole Dressed**, Pricing Basis: **Per Kilogram**, Unit: **Kg**
   - Click "+ Add to List"
7. See all 3 items in green list
8. Click "Save All (3)" → all 3 saved to Firestore

## Benefits
✅ Faster bulk commodity entry  
✅ Same Type/Commodity/Sale Method combination doesn't require reopening form  
✅ Visual confirmation of items being added (green list)  
✅ Can review and delete items before final save  
✅ One-click save for all entries  
✅ Backward compatible with single-entry workflow  
✅ Works with edit mode (existing commodities)  

## Code Changes
**File**: `lib/screens/admin/admin_commodity_page.dart`
- Added `_addedProductForms` state list
- Added `_addProductFormToList()` method
- Added `_saveAllProductForms()` method
- Updated modal UI to show added items list
- Updated action buttons to show "+ Add to List" and "Save All (n)"
- Updated `initState()` to handle edit mode

## No Breaking Changes
- Existing CSV import functionality unaffected
- Single-entry workflow still supported
- All existing commodities can still be edited
- Data model unchanged (`CommodityData` class)
