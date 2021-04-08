// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( CheckFilling () ) then
		Close ( Comment );
	endif;
	
EndProcedure
