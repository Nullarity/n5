// Description:
// Creates a new Warehouse
//
// Conditions:
// User should have default Company
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Warehouses" );

form = With ( "Warehouses (create)" );
if ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	Put ( "#Description", _.Description );
	company = _.Company;
	if ( company <> undefined ) then
		Put ( "#Owner", company );
	endif;
	value = _.Class;
	if ( value <> undefined ) then
		Put("#Class", value);
	endif;
	if ( _.Production ) then
		Click("#Production");
		if ( _.Department <> undefined ) then
			Put("#Department", _.Department);
		endif;
	endif;
else
	name = ? ( _ = undefined, "_Warehouse: " + BegOfDay ( CurrentDate () ), _ );
	Set ( "Description", name );
endif;
Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ( form );

return new Structure ( "Code, Description", code, name );
