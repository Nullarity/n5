// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	initTime ();
	
EndProcedure

&AtServer
Procedure initTime ()
	
	seconds = Parameters.Date - BegOfDay ( Parameters.Date );
	Hours = Int ( seconds / Enum.Hours1 () );
	Minutes = Int ( ( seconds - Hours * Enum.Hours1 () ) / 60 );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	setTimeLabel ();
	
EndProcedure

&AtClient
Procedure setTimeLabel ()
	
	Time = Format ( Hours, "ND=2; NZ=00; NLZ=" ) + ":" + Format ( Minutes, "ND=2; NZ=00; NLZ=" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )
	
	selectedTime = getTime ();
	NotifyChoice ( selectedTime );
	
EndProcedure

&AtClient
Function getTime ()
	
	return BegOfDay ( Parameters.Date ) + Hours * Enum.Hours1 () + Minutes * 60;
	
EndFunction 

&AtClient
Procedure HoursOnChange ( Item )
	
	setTimeLabel ();
	
EndProcedure

&AtClient
Procedure MinutesOnChange ( Item )
	
	setTimeLabel ();
	
EndProcedure
