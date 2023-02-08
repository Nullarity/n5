&AtServer
Procedure InitStart ( Object ) export
	
	if ( Object.Start = Date ( 1, 1, 1 ) ) then
		Object.Start = BegOfMinute ( CurrentSessionDate () );
	endif; 
	
EndProcedure

Procedure AdjustFinish ( Object ) export
	
	if ( Object.Finish = Date ( 1, 1, 1 ) ) then
		setDefaultFinish ( Object );
	elsif ( Object.Finish = BegOfDay ( Object.Finish ) ) then
		return;
	elsif ( Object.Finish < Object.Start ) then
		finish = Object.Start + Enum.Hours1 ();
		dayEnd = BegOfMinute ( EndOfDay ( Object.Start ) );
		Object.Finish = Min ( finish, dayEnd );
	endif; 
	
EndProcedure 

Procedure setDefaultFinish ( Object )
	
	finish = Object.Start + Enum.Hours1 ();
	dayEnd = BegOfMinute ( EndOfDay ( Object.Start ) );
	Object.Finish = Min ( finish, dayEnd );
	
EndProcedure 

Procedure CalcDuration ( Object ) export
	
	timeEnd = ? ( Object.Finish = BegOfDay ( Object.Finish ), EndOfDay ( Object.Start ), Object.Finish );
	Object.Minutes = Round ( ( timeEnd - Object.Start ) / 60 );
	Object.Duration = Conversion.MinutesToString ( Object.Minutes );
	
EndProcedure 
