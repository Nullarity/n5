// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Object.Unit.IsEmpty () ) then
		Object.Unit = Application.Unit ();
	endif; 
	if ( Parameters.FillingText <> "" ) then
		setFullDescription ( ThisObject );
	endif; 
	settings = Logins.Settings ( "Company" );
	accounts = AccountsMap.IntangibleAsset ( Catalogs.IntangibleAssets.EmptyRef (), settings.Company, "Account, Amortization" );
	Object.Account = accounts.Account;
	Object.AmortizationAccount = accounts.Amortization;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setFullDescription ( Form )
	
	object = Form.Object;
	object.FullDescription = object.Description;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	setFullDescription ( ThisObject );
	
EndProcedure
