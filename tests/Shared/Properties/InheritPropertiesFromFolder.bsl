Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create folder with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );

// ***********************************
// Test Wrong Inheritance
// ***********************************

Pick ( "#GroupsUsage", "Inherit From Parent Folder" );
Click ( "#OpenGroupsUsage" );
With ( DialogsTitle );
Get ( "* not found" ); // Error message must be shown
Click ( "OK" );

// ***********************************
// Fix the problem and continue
// ***********************************

With ( form );
Pick ( "#GroupsUsage", "Current Object Settings" );

// ***********************************
// Create properties
// ***********************************

Click ( "#OpenGroupsUsage" );
With ( DialogsTitle );
Click ( "Yes" );
With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );
__ = " " + Call ( "Common.GetID" );
Set ( "#TreeName", "Stations" + __, table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Class", table );
Click ( "#TreeInName" );

Click ( "#FormOK" );

With ( "*Construction*" );
Click ( "#FormWrite" );
code = Fetch ( "#Code" );

// ***********************************
// Navigate & expand this folder
// ***********************************

Close ();
With ( list );

table = Get ( "#List" );
table.GotoFirstRow ();
search = new Map ();
search [ "Code" ] = code;
table.GotoRow ( search );
table.Choose ();

// ***********************************
// Create a new Item
// ***********************************

Click ( "#FormCreateFolder" );
With ( "* (crea*" );
Set ( "Class", "mobile" );

// ***********************************
// Check name, description
// ***********************************

Activate ( "#Description" );
Check ( "#Description", "Stations" + __ );
CheckState ( "#Description", "ReadOnly" );
descriptionExists =  _ <> Meta.Catalogs.Features;
if ( descriptionExists ) then
	Check ( "#FullDescription", "Stations" + __ + " mobile" );
	CheckState ( "#FullDescription", "ReadOnly" );
endif;

Click ( "#FormWrite" );
