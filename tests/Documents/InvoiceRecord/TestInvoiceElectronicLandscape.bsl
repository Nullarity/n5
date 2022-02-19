With ( "Invoice Record #*" );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
Set ( "#Type", "Invoice Electronic, Landscape" );

if ( Fetch ( "#PrintBack" ) = "No" ) then
	Click ( "#PrintBack" );
endif;

if ( Fetch ( "#Transfer" ) = "No" ) then
	Click ( "#Transfer" );
endif;

Click ( "#FormPrint" );
CheckErrors ();
form = With ( "Invoice: Print" );
Close ( form );

