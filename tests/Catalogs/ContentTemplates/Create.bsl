// Description:
// Creates a new ContentTemplate
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.ContentTemplates" );
form = With ( "Templates of contents (create)" );
name = ? ( _ = undefined, "_Template: " + CurrentDate (), _ );
Set ( "#Description", name );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );

