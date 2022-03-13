// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	setControlMode ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure setControlMode ()

	ControlMode = ? ( Object.Disable, 1, 0 );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		setControlMode ();
	endif;
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Amount disable Object.Disable;
	|Customer lock filled ( Object.Customer ) and empty ( Object.Ref );
	|ThisObject lock filled ( Object.Ref );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	Object.Company = Logins.Settings ( "Company" ).Company;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ControlModeOnChange ( Item )
	
	setDisable ();
	Appearance.Apply ( ThisObject, "Object.Disable" );
	
EndProcedure

&AtClient
Procedure setDisable ()

	if ( ControlMode = 1 ) then
		Object.Disable = true;
		Object.Amount = 0;
	else
		Object.Disable = false;
	endif;

EndProcedure