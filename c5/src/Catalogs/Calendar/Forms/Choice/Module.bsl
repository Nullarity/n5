// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setDate ();
	
EndProcedure

&AtServer
Procedure setDate ()
	
	Date = DF.Pick ( Parameters.CurrentRow, "Date", CurrentSessionDate () );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	commitChoice ();
	
EndProcedure

&AtClient
Procedure commitChoice ()
	
	NotifyChoice ( getDate ( Date ) );
	
EndProcedure

&AtServerNoContext
Function getDate ( val Date )
	
	return Catalogs.Calendar.GetDate ( Date );
	
EndFunction

&AtClient
Procedure DateSelection ( Item, SelectedDate )
	
	commitChoice ();
	
EndProcedure
