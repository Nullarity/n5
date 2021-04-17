With ( "Invoice Record #*" );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
Set ( "#Type", "Invoice, Landscape" );
Click ( "#FormPrint" );
form = With ( "Invoice: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );

