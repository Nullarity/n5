if ( _ = undefined ) then
	currency = "BOB";
else
	currency = _;
endif;

// *****************************************
// Create currency from classifier
// *****************************************

form = Call ( "Common.OpenList", Meta.Catalogs.Currencies );
Click ( "#FormCreate" );

With ( "Classifier" );

table = Get ( "#List" );
search = new Map ();
search.Insert ( "Code", currency );
table.GotoFirstRow ();
table.GotoRow ( search, RowGotoDirection.Down );

Click ( "#FormSelect" );