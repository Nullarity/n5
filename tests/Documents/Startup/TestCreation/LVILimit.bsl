OpenMenu ( "Settings / Application" );
form = With ( "Application Settings" );
Activate ( "!AccountingPage" );
date = _.Date;
Put ( "!SetupDate", date );
table = Activate ( "!Settings" );
search = new Map ();
search [ "Parameter" ] = "LVI Limit";
table.GotoRow ( search, RowGotoDirection.Down );
field = table.GetObject ( , "Parameter", "SettingsDescription" );
field.Activate ();
table.Choose ();
With ( "LVI Limit: Setup" );
Put ( "!Value", _.Limit );
Put ( "#SetupDate", date );
Click ( "!FormOK" );
With ( form );
stopTrying = CurrentDate () + 3600;
IgnoreErrors = true;
while ( CurrentDate () < stopTrying ) do
	Click ( "!FormWriteAndClose" );
	try
		CheckErrors ();
		if ( Waiting ( "1?:*" ) ) then
			raise "Error appying changes";
		endif;
		break;
	except
		Close ( "1?:*" );
		Pause ( 5 );
	endtry;
enddo;
IgnoreErrors = false;
