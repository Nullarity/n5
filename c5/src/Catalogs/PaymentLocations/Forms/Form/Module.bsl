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
	
	setClass ();
	
EndProcedure

&AtClient
Procedure setClass ()
	
	account = Object.Account;
	if ( account.IsEmpty () ) then
		Object.Class = undefined;
	else
		Object.Class = DF.Pick ( account, "Class" );
	endif; 
	
EndProcedure 
