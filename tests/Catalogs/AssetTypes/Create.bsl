// Description:
// Creates new AssetType
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.AssetTypes" );
form = With ( "Asset Types (create)" );
name = ? ( _ = undefined, "_Division: " + CurrentDate (), _ );
Set ( "Description", name );

Click ( "Save" );

code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

