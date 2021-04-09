Call ( "Common.Init" );
CloseAll ();

itemName = "Item Selection, Transfer, np#";

// ***********************************
// Create Item if new
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Items;
p.Description = itemName;
creation = Call ( "Catalogs.Items.Create.Params" );
creation.Description = itemName;
creation.CountPackages = false;
p.CreationParams = creation;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Open Document
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Transfer );
Click ( "#FormCreate" );
form = With ( "Transfer (create)" );

// **************************************
// Selection without prices
// **************************************

Click ( "#ItemsSelectItems" );

With ( "Items Selection" );
CheckState ( "#GroupSelectedServices", "Visible", false );
With ( form );

p = Call ( "DataProcessors.Items.Params" );
p.Item = itemName;
Call ( "DataProcessors.Items.CommonCheck", p );
p.ShowPrices = false;
p.AskDetails = false;
p.ShowItems = false;
Click ( "#ItemsSelectItems" );
Call ( "DataProcessors.Items.CommonCheck", p );

// **************************************
// Selection with prices
// **************************************

Click ( "More / #ShowPrices" );
Activate ( "#ItemsTable" );

Click ( "#ItemsSelectItems" );
p = Call ( "DataProcessors.Items.Params" );
p.Item = itemName;
p.Prices = true;
Call ( "DataProcessors.Items.CommonCheck", p );
p.ShowPrices = false;
p.AskDetails = false;
p.ShowItems = false;
Click ( "#ItemsSelectItems" );
Call ( "DataProcessors.Items.CommonCheck", p );
