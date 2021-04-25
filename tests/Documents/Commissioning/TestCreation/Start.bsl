Call ( "Common.Init" );
CloseAll ();

env = Run ( "Create", "2CFF1CE0#" );

form = With ( "Commissioning #*" );

// ******************************************
// Test Shortage for CostOnline & CostOffline
// ******************************************

// CostOffline
Call ( "Catalogs.UserSettings.CostOnline", false );
With ( form );
table = Activate ( "#Items" );
Click ( "#ItemsEdit" );
	
With ( "Fixed Asset" );

Set ( "#Quantity", env.overlimit );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );
checkError ();

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );
With ();
Click ( "#FormPost" );
checkError ();
With ( form );
table = Activate ( "#Items" );
Click ( "#ItemsEdit" );
	
With ( "Fixed Asset" );

Set ( "#Quantity", env.recievePkg );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );

// ***********************************
// Test Logic for CostOnline & CostOffline
// ***********************************

// CostOffline
Call ( "Catalogs.UserSettings.CostOnline", false );

Click ( "#FormPost" );
Run ( "CostOffline" );

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );
With ( form );
Click ( "#FormPost" );
Run ( "Logic" );
With ( form );
return Fetch ( "#Number" );

Procedure checkError ()

	if ( FindMessages ( "Failed to post *" ).Count () = 0 ) then
		Stop ( " dialog box must be shown" );
	endif;
	Click ( "OK", Forms.Get1C () ); // Closes 1C standard dialog
	if ( FindMessages ("*").Count () <> 1 ) then
		Stop ( "Error messages must be shown one time" );
	endif;

EndProcedure
