Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/Catalog.Schedules" );
With ( "Schedules" );

table = Get ( "#List" );
GotoRow ( table, "Description", "General" );

Click ( "#FormChange" );
With ( "General (Sch*" );

table = Activate ( "#Years" );
Click ( "#YearsAdd" );

Click ( "#FormWrite" );

Put ( "#YearsMondayEvening", 2, table );
Click ( "#FormWrite" );

schedules = Activate ( "#Schedules" );
search = new Map ();
search.Insert ( "Week day", "Monday" );
schedules.GotoRow ( search );

Check ( "#SchedulesDurationEvening", "2:00", schedules );