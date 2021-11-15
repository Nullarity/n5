Call ( "Common.Init" );
CloseAll ();

Call ( "Common.OpenList", Meta.Documents.WriteOff );
Click ( "#FormCreate" );
form = With ( "Write Off (create)" );

list = "#Prices, #Amount, #Tax, #GrossAmount, #TaxGroup, #TaxCode, #Taxes";
CheckState ( list, "Enable", false );

Click ( "More / #ShowPrices" );
Activate ( "#ItemsTable" );

CheckState ( list, "Enable" );

prices = Fetch ( "#Prices" );
if ( prices = "" ) then
	Stop ( "Price type should be populated initially" );
endif;