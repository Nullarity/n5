// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	adjustMobile ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Status = Parameters.Status;
	
EndProcedure

&AtServer
Procedure adjustMobile ()
	
	if ( Environment.MobileClient () ) then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	Close ( new Structure ( "Notes, Status", Notes, Status ) );
	
EndProcedure
