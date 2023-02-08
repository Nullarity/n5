&AtClient
Procedure SelectDate ( Control, Date, LeftBound = undefined ) export
	
	p = new Structure ();
	p.Insert ( "Date", Date );
	p.Insert ( "LeftBound", LeftBound );
	OpenForm ( "CommonForm.Datetime", p, Control );
	
EndProcedure

&AtClient
Procedure SelectPeriod ( Control, DateStart, DateEnd, LeftBound = undefined, Finishing = false, Gap = 60 ) export
	
	p = new Structure ();
	p.Insert ( "Date", DateStart );
	p.Insert ( "DateTo", DateEnd );
	p.Insert ( "LeftBound", LeftBound );
	p.Insert ( "Period", true );
	p.Insert ( "Finishing", Finishing );
	p.Insert ( "Gap", Gap );
	OpenForm ( "CommonForm.Datetime", p, Control );
	
EndProcedure

Function Humanize ( Date ) export
	
	return BegOfDay ( Date ) + DatePicker.GetClose ( Date );
	
EndFunction

Function GetClose ( ByDate ) export
	
	step = DatePicker.Scale ();
	day = BegOfDay ( ByDate );
	seconds = step * Int ( ( ByDate - day ) / step );
	if ( ( day + seconds ) >= ByDate ) then
		return seconds;
	else
		return Min ( seconds + step, 86400 - step );
	endif;
	
EndFunction

Function Scale () export
	
	return 900; // 15 min
	
EndFunction
