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
	setActivationLabel ();
	setTenant ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Expensive Difficult Slow Unusable Useless enable not Record.NoReason
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setActivationLabel ()
	
	s = Items.ActivationLabel.Title;
	Items.ActivationLabel.Title = Output.FormatStr ( s, new Structure ( "Support", Cloud.Support () ) );
	
EndProcedure 

&AtServer
Procedure setTenant ()
	
	Record.Tenant = SessionParameters.Tenant;
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	adjustReasons ( CurrentObject );
	setDeactivationDate ( CurrentObject );
	
EndProcedure

&AtServer
Procedure adjustReasons ( CurrentObject )
	
	CurrentObject.NoReason = not CurrentObject.Expensive
	and not CurrentObject.Slow
	and not CurrentObject.Unusable
	and not CurrentObject.Useless
	and not CurrentObject.Difficult;
	
EndProcedure 

&AtServer
Procedure setDeactivationDate ( CurrentObject )
	
	CurrentObject.DeactivationDate = CurrentSessionDate ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Deactivate ( Command )
	
	Output.DeactivateConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure DeactivateConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.OK ) then
		deactivateProfile ();
		Terminate ();
	endif;
	
EndProcedure 

&AtServer
Procedure deactivateProfile ()
	
	Write ();
	deactivateTenant ();
	
EndProcedure 

&AtServer
Procedure deactivateTenant ()
	
	SetPrivilegedMode ( true );
	obj = SessionParameters.Tenant.GetObject ();
	obj.Deactivated = true;
	obj.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtClient
Procedure NoReasonOnChange ( Item )
	
	resetReasons ();
	Appearance.Apply ( ThisObject, "Record.NoReason" );
	
EndProcedure

&AtClient
Procedure resetReasons ()
	
	Record.Difficult = false;
	Record.Expensive = false;
	Record.Slow = false;
	Record.Unusable = false;
	Record.Useless = false;
	
EndProcedure 
