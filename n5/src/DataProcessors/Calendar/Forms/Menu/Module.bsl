// *****************************************
// *********** Group Form

&AtClient
Procedure NewTask ( Command )
	
	applyAction ( Enum.CalendarMenuNewTask () );
	
EndProcedure

&AtClient
Procedure applyAction ( Action )
	
	Close ( new Structure ( "Value", Action ) );
	
EndProcedure

&AtClient
Procedure NewCommand ( Command )
	
	applyAction ( Enum.CalendarMenuNewCommand () );
	
EndProcedure

&AtClient
Procedure NewTimeEntry ( Command )
	
	applyAction ( Enum.CalendarMenuNewTimeEntry () );
	
EndProcedure

&AtClient
Procedure NewProject ( Command )
	
	applyAction ( Enum.CalendarMenuNewProject () );
	
EndProcedure

&AtClient
Procedure NewMeeting ( Command )
	
	applyAction ( Enum.CalendarMenuNewMeeting () );
	
EndProcedure

&AtClient
Procedure NewEvent ( Command )

	applyAction ( Enum.CalendarMenuNewEvent () );

EndProcedure

