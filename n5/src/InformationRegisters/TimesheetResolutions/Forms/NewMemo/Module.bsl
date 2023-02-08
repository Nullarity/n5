// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setTimesheetsResolutionsParams ();
	
EndProcedure

&AtServer
Procedure setTimesheetsResolutionsParams ()
	
	Resolutions.Parameters.SetParameterValue ( "TimesheetApproval", Record.TimesheetApproval );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	CurrentObject.User = SessionParameters.User;
	CurrentObject.Date = CurrentSessionDate ();
	
EndProcedure

// *****************************************
// *********** Group

&AtClient
Procedure WriteAndClose ( Command )
	
	if ( Write () ) then
		Close ( Record.Memo );
	endif; 
	
EndProcedure
