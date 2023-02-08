// *****************************************
// *********** Form events

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkHours () ) then
		Cancel = true;
	endif; 
	
EndProcedure

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
