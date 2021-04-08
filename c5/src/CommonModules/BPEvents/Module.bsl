
Procedure Prefix ( Source, StandardProcessing, Prefix ) Export
	
	px = Application.Prefix ();
	if ( px = "" ) then
		return;
	endif;
	Prefix = px;
	
EndProcedure
