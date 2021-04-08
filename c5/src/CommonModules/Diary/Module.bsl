
Function GetWeekInfo ( val Schedule ) export
	
	s = "
	|select Schedules.Start as Start, Schedules.Finish as Finish,
	|	case when Schedules.DayOff1 = value ( Enum.Week.Monday ) then 1
	|		when Schedules.DayOff1 = value ( Enum.Week.Tuesday ) then 2
	|		when Schedules.DayOff1 = value ( Enum.Week.Wednesday ) then 3
	|		when Schedules.DayOff1 = value ( Enum.Week.Thursday ) then 4
	|		when Schedules.DayOff1 = value ( Enum.Week.Friday ) then 5
	|		when Schedules.DayOff1 = value ( Enum.Week.Saturday ) then 6
	|		when Schedules.DayOff1 = value ( Enum.Week.Sunday ) then 7
	|		else 0
	|	end as DayOff1,
	|	case when Schedules.DayOff2 = value ( Enum.Week.Monday ) then 1
	|		when Schedules.DayOff2 = value ( Enum.Week.Tuesday ) then 2
	|		when Schedules.DayOff2 = value ( Enum.Week.Wednesday ) then 3
	|		when Schedules.DayOff2 = value ( Enum.Week.Thursday ) then 4
	|		when Schedules.DayOff2 = value ( Enum.Week.Friday ) then 5
	|		when Schedules.DayOff2 = value ( Enum.Week.Saturday ) then 6
	|		when Schedules.DayOff2 = value ( Enum.Week.Sunday ) then 7
	|		else 0
	|	end as DayOff2,
	|	case when Schedules.WeekStart = value ( Enum.Week.Monday ) then 1
	|		when Schedules.WeekStart = value ( Enum.Week.Tuesday ) then 2
	|		when Schedules.WeekStart = value ( Enum.Week.Wednesday ) then 3
	|		when Schedules.WeekStart = value ( Enum.Week.Thursday ) then 4
	|		when Schedules.WeekStart = value ( Enum.Week.Friday ) then 5
	|		when Schedules.WeekStart = value ( Enum.Week.Saturday ) then 6
	|		when Schedules.WeekStart = value ( Enum.Week.Sunday ) then 7
	|	end as WeekStart
	|from Catalog.Schedules as Schedules
	|where Schedules.Ref = &Schedule
	|";
	q = new Query ( s );
	q.SetParameter ( "Schedule", Schedule );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
EndFunction 

Procedure SqlHolidays ( Env ) export
	
	s = "
	|// #Holidays
	|select List.Day as Day
	|from InformationRegister.Holidays as List
	|	//
	|	// Schedules
	|	//
	|	join Catalog.Schedules as Schedules
	|	on Schedules.Ref = &Schedule
	|	and Schedules.Holidays = List.Reference
	|where List.Day between &DateStart and &DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Function ConvertTotalsByDaysToMap ( Env ) export
	
	totals = new Map ();
	for each row in Env.TotalsByDays do
		totals [ row.Date ] = row.Minutes;
	enddo; 
	return totals;
	
EndFunction

Function ConvertHolidaysToMap ( Env ) export
	
	holidays = new Map ();
	for each row in Env.Holidays do
		holidays [ row.Day ] = true;
	enddo; 
	return holidays;
	
EndFunction 

Function ColorsMap ( Env ) export
	
	set = new Map ();
	for each row in Env.CalendarAppearance do
		set [ row.Code ] = new Structure ( "Color, BackColor", Colors.Deserialize ( row.Color ), Colors.Deserialize ( row.BackColor ) );
	enddo;
	return set;
	
EndFunction 
