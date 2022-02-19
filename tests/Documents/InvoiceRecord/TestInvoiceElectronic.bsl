With ( "Invoice Record #*" );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
Set ( "#Type", "Invoice Electronic" );
Click ( "#FormPrint" );
CheckErrors ();
form = With ( "Invoice: Print" );
Close ( form );

