Call ( "Common.Init" );
CloseAll ();

defValue = "auto";

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

Click ( "#Add" );
Set ( "#TreeName", "Valve", table );
Set ( "#TreeDefaultValue", defValue );

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

Check ( "#Description", defValue );
descriptionExists =  _ <> Meta.Catalogs.Features;
if ( descriptionExists ) then
	Check ( "#FullDescription", defValue );
endif;
