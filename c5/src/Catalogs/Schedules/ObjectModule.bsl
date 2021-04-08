#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkYearDoubles () ) then
		Cancel = true;
		return;
	endif; 
	checkTimesheetDays ( CheckedAttributes );
	checkDaysOff ( CheckedAttributes );
	
EndProcedure

Procedure checkTimesheetDays ( CheckedAttributes )
	
	if ( TimesheetPeriod = Enums.TimesheetPeriods.Other ) then
		CheckedAttributes.Add ( "TimesheetDays" );
	endif; 
	
EndProcedure 

Function checkYearDoubles ()
	
	doubles = Collections.GetDoubles ( Years, "Year" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.YearAlreadyExists ( , Output.Row ( "Years", row.LineNumber, "Year" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure checkDaysOff ( CheckedAttributes )
	
	if ( not DayOff2.IsEmpty () ) then
		CheckedAttributes.Add ( "DayOff1" );
	endif; 
	
EndProcedure 

#endif