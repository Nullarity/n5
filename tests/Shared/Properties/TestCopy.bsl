Call ( "Common.Init" );
CloseAll ();

itemType = "type: " + Call ( "Common.GetID" );

// ***********************************
// Create folder with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );

// ***********************************
// Create properties
// ***********************************

Pick ( "#ItemsUsage", "Current Object Settings" );
Click ( "#OpenItemsUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );
Set ( "#TreeName", "Valve", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Class", table );

Click ( "#FormOK" );

With ( form );

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

Click ( "#FormCreate" );
With ( "* (crea*" );
Set ( "Class", itemType );

// ***********************************
// Save & Copy & Test copied fields
// ***********************************

Activate ( "#Description" );
name = Fetch ( "#Description" );
descriptionExists =  _ <> Meta.Catalogs.Features;
if ( descriptionExists ) then
	fullName = Fetch ( "#FullDescription" );
endif;

Click ( "#FormWrite" );
Click ( "#FormCopy" );

With ( "* (crea*" );
Check ( "#PropertiesGroup / Class", itemType );
Check ( "#Description", name );
if ( descriptionExists ) then
	Check ( "#FullDescription", fullName );
endif;
