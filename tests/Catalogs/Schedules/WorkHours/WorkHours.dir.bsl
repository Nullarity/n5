// Description:
// Returns work hours between two dates by selected schedule
//
// Parameters:
// Catalogs.Schedules.WorkHours.Params
//
// Returns:
// Number, work hours

schedule = _.Schedule;
dateStart = _.DateStart;
dateEnd = _.DateEnd;

Commando ( "e1cib/list/InformationRegister.Schedules" );
form = With ( "Schedules" );

// Filter by schedule
Click ( "#FormFind" );
With ( "Find" );
Pick ( "#FieldSelector", "Schedule" );
Put ( "#Pattern", schedule );
Click ( "#Find" );

// Filter by schedule
With ( form );
Click ( "#FormFind" );
With ( "Find" );
Pick ( "#FieldSelector", "Year" );
Put ( "#Pattern", Format ( Year ( dateStart ), "NG=0" ) );
Click ( "#Find" );

// Find hours
With ( form );
table = Get ( "#List" );
table.GotoFirstRow ();
lastDay = dateEnd;
day = dateStart;
workHours = 0;
search = new Map ();
search [ "Schedule" ] = schedule;
while ( day <= lastDay ) do
	search [ "Day" ] = Format ( day, "DLF=D" );
	table.GotoRow ( search );
	hours = Fetch ( "#Duration", table );
	if ( hours = "" ) then
	else
		workHours = workHours + Number ( StrReplace ( hours, ":", "." ) );
	endif;
	day = day + 86400;
enddo;
Close ( form );
return workHours;
