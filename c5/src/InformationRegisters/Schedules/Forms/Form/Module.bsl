// *****************************************
// *********** Form events

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkYearAndDay () ) then
		Cancel = true;
	endif; 
	if ( not checkHours () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkYearAndDay ()
	
	if ( Record.Year <> Year ( Record.Day ) ) then
		Output.InvalidScheduleDay ( , "Day", , "Record" );
		return false;
	endif; 
	return true;
	
EndFunction 

&AtServer
Function checkHours ()
	
	if ( ( Record.Duration - Record.DurationEvening - Record.DurationNight ) < 0 ) then
		Output.WrongTotalHours ( , "Duration" );
		return false;
	endif; 
	return true;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure DurationOnChange ( Item )
	
	Conversion.AdjustTime ( Record.Duration );
	calcMinutes ();
	
EndProcedure

&AtClient
Procedure calcMinutes ()
	
	Record.Minutes = Conversion.DurationToMinutes ( Record.Duration );
	
EndProcedure 