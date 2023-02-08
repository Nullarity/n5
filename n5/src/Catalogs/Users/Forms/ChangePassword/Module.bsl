// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Cloud.SaaS ()
		and Connections.IsDemo () ) then
		Output.DemoMode ();
		Cancel = true;
		return;
	endif; 
	Forms.ResetWindowSettings ( ThisObject );
	setWarningVisible ();
	
EndProcedure

&AtServer
Procedure setWarningVisible ()
	
	Items.WarningGroup.Visible = Parameters.Property ( "ChangePasswordBeforeStartApplication" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Change ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	if ( not checkPassword () ) then
		return;
	endif; 
	changePassword ( Password );
	Close ( true );
	
EndProcedure

&AtClient
Function checkPassword ()
	
	error = Password <> PasswordConfirmation;
	if ( error ) then
		Output.InvalidPasswordAndConfirmation ( , "PasswordConfirmation", , "" );
	endif;
	return not error;
	
EndFunction 

&AtServerNoContext
Procedure changePassword ( Password )
	
	SetPrivilegedMode ( true );
	LoginsSrv.ChangePassword ( SessionParameters.User, Password );
	LoginsSrv.ResetMustChangePassword ();
	
EndProcedure 
