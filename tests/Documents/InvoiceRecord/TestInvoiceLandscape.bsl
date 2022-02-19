With ( "Invoice Record #*" );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
Set ( "#Type", "Invoice, Landscape" );
Click ( "#FormPrint" );
CheckErrors ();
With ();
Close ();