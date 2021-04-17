Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/InformationRegister.Schedules" );
With ();

Click ( "#FormChange" );
With ();

Set ( "#Duration", 8 );
Set ( "#DurationNight", 9 );

StandardProcessing = false;
Click ( "#FormWrite" );
msg = "Evening and Night hours *";
if ( FindMessages ( msg ).Count () <> 1 ) then
	Stop ( "<" + msg + "> error messages must be shown one time" );
endif;
