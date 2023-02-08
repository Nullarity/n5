&AtServer
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	if ( Object.Taxes ) then
		readAccount ();
		labelDims ();
	endif;
	updateWarning ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.AccountTax );
	DimLevel = AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ()
	
	i = 1;
	for each dim in AccountData.Dims do
		Items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
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
	defineAccountOwner ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure defineAccountOwner ( Form )
	
	type = TypeOf ( Form.Object.Owner );
	if ( type = Type ( "CatalogRef.Organizations" ) ) then
		Form.AccountOwner = 1;
	else
		Form.AccountOwner = 0;
	endif;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner lock filled ( Object.Owner );
	|WrongAccount show WrongAccount;
	|Taxes show AccountOwner = 1;
	|AccountTax show Object.Taxes;
	|Dim1 show DimLevel > 0 and Object.Taxes;
	|Dim2 show DimLevel > 1 and Object.Taxes;
	|Dim3 show DimLevel > 2 and Object.Taxes;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	Object.Currency = Application.Currency ();
	if ( Object.Owner = undefined ) then
		Object.Owner = Logins.Settings ( "Company" ).Company;
	endif;
	
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

	defineAccountOwner ( ThisObject );
	if ( AccountOwner <> 1 ) then
		Object.Taxes = false;
		applyTaxes ();
	endif;
	Appearance.Apply ( ThisObject, "AccountOwner" );
	
EndProcedure

&AtClient
Procedure applyTaxes ()
	
	if ( not Object.Taxes ) then
		Object.AccountTax = undefined;
		Object.Dim1 = undefined;
		Object.Dim2 = undefined;
		Object.Dim3 = undefined;
		DimLevel = 0;
	endif;
	Appearance.Apply ( ThisObject, "Object.Taxes" );

EndProcedure

&AtClient
Procedure TaxesOnChange ( Item )
	
	applyTaxes ();

EndProcedure

&AtClient
Procedure AccountTaxOnChange ( Item )
	
	applyAccount ();

EndProcedure

&AtServer
Procedure applyAccount ()
	
	readAccount ();
	adjustDims ( AccountData, Object );
	labelDims ();
	Appearance.Apply ( ThisObject, "DimLevel" );
	      	
EndProcedure 

&AtServer
Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure
