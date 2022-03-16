// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	setControlMode ();
	Constraints.ShowAccess ( ThisObject );
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
		Constraints.ShowAccess ( ThisObject );
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

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

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