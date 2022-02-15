// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Owner.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Owner = settings.Company;
	endif;
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Remote enable Object.Register
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group form

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtClient
Procedure applyAccount ()
	
	account = Object.Account;
	if ( account.IsEmpty () ) then
		Object.Class = undefined;
	else
		class = DF.Pick ( account, "Class" );
		Object.Class = class;
		if ( class = PredefinedValue ( "Enum.Accounts.Cash" ) ) then
			Object.Method = PredefinedValue ( "Enum.PaymentMethods.Cash" );
		else
			Object.Method = PredefinedValue ( "Enum.PaymentMethods.Bank" );
		endif;
	endif;
	
EndProcedure 

&AtClient
Procedure RegisterOnChange ( Item )
	
	applyRegister ();

EndProcedure

&AtClient
Procedure applyRegister ()
	
	if ( not Object.Register ) then
		Object.Remote = false;
	endif;
	Appearance.Apply ( ThisObject, "Object.Register" );

EndProcedure
