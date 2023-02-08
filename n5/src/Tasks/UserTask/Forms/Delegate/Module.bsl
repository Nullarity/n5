// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( CheckFilling () ) then
		Close ( new Structure ( "Performer, Notes", Performer, Notes ) );
	endif;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	adjustMobile ();
	
EndProcedure

&AtServer
Procedure adjustMobile ()
	
	if ( Environment.MobileClient () ) then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	endif;
	
EndProcedure
