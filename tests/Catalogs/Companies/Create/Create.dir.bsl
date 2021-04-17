// Description:
// Creates new Company
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Companies" );
form = With ( "Companies (create)" );
if ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	Put ( "#Description", _.Description );
	if ( _.Discounts ) then
		Click ( "#Discounts" );
	endif;
else
	name = ? ( _ = undefined, "_Company: " + CurrentDate (), _ );
	Put ( "#Description", name );
endif;

Click ( "Save" );

code = Fetch ( "Code" );

Close ( form );

return new Structure ( "Code, Description", code, name );
