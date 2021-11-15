
itemName = _.Item;
feature = _.Feature;

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

if ( feature <> undefined ) then
	Set ( "#ItemsFeature", feature );
endif;

Set ( "#ItemsPrices", _.Prices );
Set ( "#ItemsPrice", _.Price );
Click ( "#FormPostAndClose" );
