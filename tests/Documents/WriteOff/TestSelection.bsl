Call ( "Common.Init" );
CloseAll ();

itemName = "Item Selection, WriteOff, np#";

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

Call ( "Common.OpenList", Meta.Documents.WriteOff );
Click ( "#FormCreate" );
form = With ( "Write Off (create)" );

// **************************************
// Selection without prices
// **************************************

Click ( "#ItemsSelectItems" );
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
