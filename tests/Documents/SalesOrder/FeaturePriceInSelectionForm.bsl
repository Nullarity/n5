
Call ( "Common.Init" );
CloseAll ();

itemName = "_Item test feature price#";
featureName = "_white#";
prices = "Cost";
price = "7";

// ***********************************
// Create Item & Feature
// ***********************************

itemParams = Call ( "Catalogs.Items.Create.Params" );
itemParams.Description = itemName;
itemParams.Feature = featureName;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Items;
p.Description = itemName;
p.CreationParams = itemParams;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Setup Price
// ***********************************

p = Call ( "Documents.SetupPrices.Simple.Params" );
p.Item = itemName;
p.Feature = featureName;
p.Prices = prices;
p.Price = price;
Call ( "Documents.SetupPrices.Simple.Create", p );

// *************************************
// Create Sales Order and Open Selection
// *************************************

MainWindow.ExecuteCommand ( "e1cib/data/Document.SalesOrder" );
form = With ( "Sales Order (create)" );
Set ( "#Prices", prices );

With ( "1C:*" );
Click ( "Yes" );

With ( form );
form.GotoNextItem ();

Click ( "#ItemsSelectItems" );
With ( "Items Selection" );

// *************************************
// Enable prices
// *************************************

flag = Fetch ( "#ShowPrices" );
if ( flag = "No" ) then
	Click ( "#ShowPrices" );
endif;

// *************************************
// Search Item and Feature
// *************************************

p = Call ( "Common.Find.Params" );
p.Where = "Item";
p.What = itemName;
p.Button = "#ItemsListContextMenuFind";
Call ( "Common.Find", p );

table = Get ( "#ItemsList" );
table.Choose ();

table = Get ( "#FeaturesList" );
table.GotoFirstRow ();

// *************************************
// Search & Check Price
// *************************************

table = Activate ( "#Prices" );
search = new Map ();
search [ "Prices" ] = prices + ", USD";
table.GotoFirstRow ();
Pause ( 1 );
table.GotoRow ( search );

actualPrice = Fetch ( "#PricesPrice", table );
if ( actualPrice = "" or ( Number ( actualPrice ) <> Number ( price ) ) ) then
	Stop ( "Price in price table should be " + price + ", however actual value is " + actualPrice );
endif;
