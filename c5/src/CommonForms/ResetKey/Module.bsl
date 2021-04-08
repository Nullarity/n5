// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readLicense ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Reset show CurrentStep = 0;
	|FormOK show CurrentStep = 1
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure readLicense ()
	
	License = Constants.License.Get ();
	OldLicense = License;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( CurrentStep = 0 ) then
		CheckedAttributes.Add ( "License" );
	elsif ( CurrentStep = 1 ) then
		CheckedAttributes.Add ( "AccessKey" );
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Reset ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	resetKey ();
	
EndProcedure

&AtServer
Procedure resetKey ()
	
	saveLicense ();
	Email = sendRequest ();
	CurrentStep = CurrentStep + 1;
	Items.Pages.CurrentPage = Items.Page2;
	Appearance.Apply ( ThisObject, "CurrentStep" );
	
EndProcedure

&AtServer
Procedure saveLicense ()
	
	if ( OldLicense = License ) then
		return;
	endif;
	Constants.License.Set ( License );
	OldLicense = License;
	
EndProcedure

&AtServer
Function sendRequest ()
	
	address = DataProcessors [ Enum.DataProcessorsLicensing () ].Reset ();
	if ( address = undefined ) then
		raise Output.AccessKeyResettingError ();
	endif;
	return address;
	
EndFunction

&AtClient
Procedure OK ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	saveKey ( AccessKey );
	if ( SessionInfo.Testing ) then
		Output.CloseApplicationManually ();
	else
		Close ( true );
	endif;

EndProcedure

&AtServerNoContext
Procedure saveKey ( val NewKey )
	
	Constants.Key.Set ( NewKey );
	
EndProcedure
