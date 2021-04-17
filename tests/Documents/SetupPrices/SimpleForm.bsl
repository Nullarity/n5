Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create Item
// ***********************************

itemName = "_Item test simple Setup Prices";
Call ( "Catalogs.Items.CreateIfNew", itemName );

// ***********************************
// Open Item from list
// ***********************************

Call ( "Common.OpenList", Meta.Catalogs.Items );
Clear ( "#WarehouseFilter" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = itemName;
Call ( "Common.Find", p );

Activate ( "#List" );
Click ( "#FormChange" );

With ( itemName + "*" );

// ***********************************
// Open embedded Prices inforeg
// ***********************************

Click ( "Prices", GetLinks () );
With ( "Prices" );

Click ( "#FormNew" );
With ( "Setup Prices (create)" );

Set ( "#ItemsPrices", "Cost" );
Set ( "#ItemsPrice", "5" );
Click ( "#FormPost" );

// ***********************************
// Test Copy
// ***********************************

Click ( "#FormCopy" );
