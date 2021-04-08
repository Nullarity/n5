// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Calendar = Parameters.Date;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CalendarOnActivateDate ( Item )
	
	Close ( Calendar );
	
EndProcedure
