
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	protectSetting ();

EndProcedure

&AtServer
Procedure protectSetting ()

	if ( Object.User = SessionParameters.User ) then
		Items.Warning.Visible = false;
	else
		Items.Warning.Visible = true;
		ReadOnly = true;
	endif;

EndProcedure