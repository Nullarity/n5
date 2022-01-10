// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
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
