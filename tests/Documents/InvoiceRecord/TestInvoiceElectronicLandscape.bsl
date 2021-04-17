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
form = With ( "Invoice: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );

