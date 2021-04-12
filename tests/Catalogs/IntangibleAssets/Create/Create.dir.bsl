// Description:
// Creates a new Item
//
// Parameters:
// Catalogs.IntangibleAssets.Create.Params
//
// Returns:
// Structure ( "Code, Description" )

name = _.Description;

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.IntangibleAssets" );
With ( "Intangible Assets (cr*" );
Set ( "#Description", name );

if ( AppName = "c5" ) then
	value = _.VAT;
	if ( value <> undefined ) then
		Put ( "#VAT", value );
	endif;
endif;

Click ( "#FormWrite" );
code = Fetch ( "#Code" );
Close ();

return new Structure ( "Code, Description", code, name );
