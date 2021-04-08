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
	
	if ( CheckFilling () ) then
		Close ( new Structure ( "Notes, Status", Reason, Status ) );
	endif;
	
EndProcedure
