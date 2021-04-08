// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateWarning ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure updateWarning ( Form )
	
	object = Form.Object;
	account = object.AccountNumber;
	if ( account = "" ) then
		Form.WrongAccount = false;		
	else
		Form.WrongAccount = accountExists ( account, object.Ref );		
	endif;
	Appearance.Apply ( Form, "WrongAccount" );
	
EndProcedure

&AtServerNoContext
Function accountExists ( val Account, val Ref )
	
	s = "
	|select top 1 1
	|from Catalog.BankAccounts as Accounts
	|where Accounts.AccountNumber = &Account
	|and Accounts.Ref <> &Ref
	|and not Accounts.DeletionMark";
	q = new Query ( s );
	q.SetParameter ( "Account", Account );
	q.SetParameter ( "Ref", Ref );
	SetPrivilegedMode ( true );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		updateWarning ( ThisObject );
	endif;
	setCompanyAccount ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setCompanyAccount ( Form )
	
	Form.CompanyAccount = TypeOf ( Form.Object.Owner ) = Type ( "CatalogRef.Companies" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner lock filled ( Object.Owner );
	|GroupBanking show CompanyAccount;
	|WrongAccount show WrongAccount;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	Object.Currency = Application.Currency ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure BankOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = Conversion.ValuesToString ( Object.Bank, Object.AccountNumber );
	
EndProcedure 

&AtClient
Procedure AccountNumberOnChange ( Item )
	
	setDescription ();
	updateWarning ( ThisObject );
	
EndProcedure

&AtClient
Procedure OwnerOnChange ( Item )
	
	applyOwner ();
	
EndProcedure

&AtClient
Procedure applyOwner ()

	setCompanyAccount ( ThisObject );
	if ( not CompanyAccount ) then
		Object.Application = undefined;
	endif;
	Appearance.Apply ( ThisObject, "CompanyAccount" );
	
EndProcedure

&AtClient
Procedure UnloadingStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	BankingForm.ChooseUnloading ( Object.Application, Item );

EndProcedure

&AtClient
Procedure LoadingStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	BankingForm.ChooseLoading ( Object.Application, Item );
	
EndProcedure
