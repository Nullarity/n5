Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/Catalog.Schedules" );
With ( "Schedules" );

table = Get ( "#List" );
GotoRow ( table, "Description", "General" );

Click ( "#FormChange" );
With ( "General (Sch*" );

table = Activate ( "#Years" );
Put ( "#YearsMondayEvening", 9, table );

StandardProcessing = false;
Click ( "#FormWrite" );
msg = "Evening and Night hours *";
if ( FindMessages ( msg ).Count () <> 1 ) then
	Stop ( "<" + msg + "> error messages must be shown one time" );
endif;
