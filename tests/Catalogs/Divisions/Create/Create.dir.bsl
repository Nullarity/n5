// Description:
// Creates new Division
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Divisions" );
form = With ( "Divisions (create)" );
if ( _ = undefined ) then
	name = "_Division: " + CurrentDate ();
elsif ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	name = _.Description;
	if ( _.Company <> undefined ) then
		Put ( "#Owner", _.Company );
	endif;
	Put ( "#Cutam", _.Cutam );
else
	name = _;
endif;
Put ( "#Description", name );

Click ( "Save" );

code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );
