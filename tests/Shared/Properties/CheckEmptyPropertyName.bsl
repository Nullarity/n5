Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create item with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreate" );
form = With ( "* (create*" );

// ***********************************
// Create properties
// ***********************************

Pick ( "#ObjectUsage", "Current Object Settings" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );

Click ( "#TreeAdd" );
Clear ( "#TreeType" );

Click ( "#FormOK" );

// ***********************************
// Save and check mandatory field
// ***********************************

With ( form );

Click ( "#FormWrite" );

if ( FindMessages ( "Field * is empty" ).Count () = 0 ) then
	Stop ( "Error message must be shown" );
else
	StandardProcessing = false;
endif;
