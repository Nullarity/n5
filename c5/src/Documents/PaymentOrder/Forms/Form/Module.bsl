&AtServer
var Env;
&AtServer
var Base;
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
	InvoiceForm.SetLocalCurrency ( ThisObject );
	setPrintPaymentContent ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.Account );
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

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			fillNew ();
		else
			baseType = TypeOf ( Parameters.Basis );
			if ( baseType = Type ( "DocumentRef.PayEmployees" )
				or baseType = Type ( "DocumentRef.PayAdvances" ) ) then
				fillByPayEmployees ();
			endif; 
		endif; 
		Constraints.ShowAccess ( ThisObject );
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|PaidWarning show Object.Paid;
	|Base show filled ( Object.Base );
	|Contract enable Object.Recipient <> Object.Company and not Object.Paid;
	|VAT enable filled ( Object.VATRate ) and not Object.Paid;
	|IncomeTax enable Object.IncomeTaxRate > 0 and not Object.Paid;
	|Amount lock Object.Salary or Object.Paid;
	|VATRate IncomeTaxRate ExcludeTaxes Taxes ToCompany hide Object.Salary;
	|Account show Object.Taxes;
	|Dim1 show DimLevel > 0 and Object.Taxes;
	|Dim2 show DimLevel > 1 and Object.Taxes;
	|Dim3 show DimLevel > 2 and Object.Taxes;
	|PaidBy show Object.Paid;
	|Company BankAccount TerritorialDepartment Recipient ContractorPresentation
	|RecipientBankAccount CashFlow VATRate IncomeTaxRate Taxes Account Dim1 Dim2 Dim3 PaymentContent
	|PrintPaymentContent ExcludeTaxes Unload Urgent ToCompany Number Date
	|	lock Object.Paid;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()

	if ( Parameters.CopyingValue.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
		Object.BankAccount = DF.Pick ( Object.Company, "BankAccount" );
		setRecipient ();
		applyRecipient ();
		setPrintPaymentContent ();
	else
		Object.Paid = false;
		Object.PaidBy = undefined;
		Object.Unload = true;
	endif;
	
EndProcedure

&AtServer
Procedure setRecipient ()

	if ( Object.ToCompany ) then
		Object.Recipient = Object.Company;
	elsif ( Object.Recipient = undefined
		or TypeOf ( Object.Recipient ) = Type ( "CatalogRef.Companies" ) ) then
		Object.Recipient = Catalogs.Organizations.EmptyRef ();
	endif;

EndProcedure

&AtServer
Procedure applyRecipient ()

	setContract ();
	setRecipientBankAccount ();
	setRecipientPresentation ();
	
EndProcedure

&AtServer
Procedure setContract ()

	if ( Object.ToCompany ) then
		Object.Contract = Catalogs.Contracts.EmptyRef ();
	else
		Object.Contract = getContract ();
	endif;

EndProcedure

&AtServer
Function getContract ()
	
	s = "
	|select 1 as Priority, Organizations.VendorContract as Ref
	|from Catalog.Organizations as Organizations
	|where Organizations.Ref = &Organization
	|and Organizations.VendorContract <> value ( Catalog.Contracts.EmptyRef )
	|and VendorContract.Company = &Company
	|union all
	|select 2, Organizations.CustomerContract
	|from Catalog.Organizations as Organizations
	|where Organizations.Ref = &Organization
	|and Organizations.CustomerContract <> value ( Catalog.Contracts.EmptyRef )
	|and CustomerContract.Company = &Company
	|order by Priority";
	q = new Query ( s );
	q.SetParameter ( "Organization", Object.Recipient );
	q.SetParameter ( "LocalCurrency", LocalCurrency );
	q.SetParameter ( "Company", Object.Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

&AtServer
Procedure setRecipientBankAccount ()

	if ( Object.ToCompany ) then
		Object.RecipientBankAccount = DF.Pick ( Object.Recipient, "BankAccount" );
	else
		Object.RecipientBankAccount = organizationBank ();
	endif;
	applyRecipientBankAccount ();

EndProcedure

&AtServer
Procedure applyRecipientBankAccount ()
	
	if ( Object.ToCompany ) then
		Object.Taxes = false;
	else
		fields = DF.Values ( Object.RecipientBankAccount, "Taxes, AccountTax as Account, Dim1, Dim2, Dim3" );
		FillPropertyValues ( Object, fields );
		if ( not Object.Account.IsEmpty () ) then
			applyAccount ();
		endif;
	endif;
	applyTaxes ();				

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

&AtServer
Function organizationBank ()
	
	s = "
	|select 1 as Priority, Contracts.VendorBank as Ref
	|from Catalog.Contracts as Contracts
	|where Contracts.Ref = &Ref
	|and Contracts.Vendor
	|union all
	|select 2, Contracts.CustomerBank
	|from Catalog.Contracts as Contracts
	|where Contracts.Ref = &Ref
	|and Contracts.Customer
	|order by Priority";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Contract );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

&AtServer
Procedure setRecipientPresentation ()
	
	if ( ValueIsFilled ( Object.Recipient ) ) then
		Object.RecipientPresentation = ? ( DF.Pick ( Object.Recipient, "Alien" ), "(N) ", "(R) " ) + DF.Pick ( Object.Recipient, "FullDescription" );
	endif;
	
EndProcedure

&AtServer
Procedure setPrintPaymentContent ()

	PrintPaymentContent = FormAttributeToValue ( "Object" ).GetPrintPaymentContent ();

EndProcedure

&AtServer
Procedure fillByPayEmployees ()
	
	SQL.Init ( Env );
	Env.Insert ( "BaseName", Metadata.FindByType ( TypeOf ( Parameters.Basis ) ).Name );
	sqlPayEmployees ();
	Env.Q.SetParameter ( "Base", Parameters.Basis );
	SQL.Perform ( Env );
	checkPayEmployees ();
	Object.Base = Base;
	Object.Salary = true;
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	setRecipient ();
	applyRecipient ();
	setPrintPaymentContent ();

EndProcedure

&AtServer
Procedure sqlPayEmployees ()
	
	s = "
	|// @Fields
	|select Documents.Amount as Amount, Documents.BankAccount as BankAccount,
	|	Documents.BankAccount.Bank.Organization as Recipient, Documents.CashFlow as CashFlow,
	|	Documents.Company as Company, Documents.Posted as Posted
	|from Document." + Env.BaseName + " as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure checkPayEmployees ()
	
	if ( not Env.Fields.Posted ) then
		raise Output.BaseNotPosted ();
	endif;
	
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
Procedure RecipientOnChange ( Item )
	
	applyRecipient ();
	
EndProcedure

&AtClient
Procedure RecipientBankAccountOnChange ( Item )
	
	applyRecipientBankAccount ();

EndProcedure

&AtClient
Procedure ToCompanyOnChange ( Item )
	
	applyToCompany ();
	
EndProcedure

&AtClient
Procedure applyToCompany ()

	setRecipient ();
	applyRecipient ();
	Object.CashFlow = PredefinedValue ( "Catalog.CashFlows.EmptyRef" );
	Appearance.Apply ( ThisObject, "Object.Recipient" );

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtClient
Procedure applyCompany ()

	setRecipient ();
	applyRecipient ();
	Appearance.Apply ( ThisObject, "Object.Recipient" );

EndProcedure

&AtClient
Procedure VATRateOnChange ( Item )
	
	applyVATRate ();
	
EndProcedure

&AtServer
Procedure applyVATRate () 

	calcVAT ();
	setPrintPaymentContent ();
	Appearance.Apply ( ThisObject, "Object.VATRate" );

EndProcedure

&AtServer
Procedure calcVAT () 

	amount = Object.Amount;
	Object.VAT = amount - amount * 100 / ( 100 + DF.Pick ( Object.VATRate, "Rate" ) );

EndProcedure

&AtClient
Procedure IncomeTaxRateOnChange ( Item )
	
	applyIncomeTaxRate ();
	
EndProcedure

&AtServer
Procedure applyIncomeTaxRate () 

	calcIncomeTax ();
	setPrintPaymentContent ();
	Appearance.Apply ( ThisObject, "Object.IncomeTaxRate" );

EndProcedure

&AtServer
Procedure calcIncomeTax () 

	Object.IncomeTax = ( Object.Amount - Object.VAT ) / 100 * Object.IncomeTaxRate;

EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	setRecipientBankAccount ();
	
EndProcedure

&AtClient
Procedure TaxesOnChange ( Item )
	
	applyTaxes ();
	
EndProcedure

&AtServer
Procedure applyTaxes ()
	
	if ( not Object.Taxes ) then
		Object.Account = undefined;
		Object.Dim1 = undefined;
		Object.Dim2 = undefined;
		Object.Dim3 = undefined;
		DimLevel = 0;
	endif;
	Appearance.Apply ( ThisObject, "Object.Taxes" );

EndProcedure

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtClient
Procedure PaymentContentOnChange ( Item )
	
	setPrintPaymentContent ();
	
EndProcedure

&AtClient
Procedure PaymentContentStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	selectTemplate ();
	
EndProcedure

&AtClient
Procedure selectTemplate ()
	
	OpenForm ( "Catalog.ContentTemplates.ChoiceForm", , Items.PaymentContent );
	
EndProcedure
	
&AtClient
Procedure AmountOnChange ( Item )
	
	applyAmount ();
	
EndProcedure

&AtServer
Procedure applyAmount () 

	calcVAT ();
	calcIncomeTax ();
	setPrintPaymentContent ();

EndProcedure

&AtClient
Procedure VATSumOnChange ( Item )
	
	setPrintPaymentContent ();
	
EndProcedure

&AtClient
Procedure IncomeTaxSumOnChange ( Item )
	
	setPrintPaymentContent ();
	
EndProcedure

&AtClient
Procedure ExcludeTaxesOnChange ( Item )
	
	setPrintPaymentContent ();
	
EndProcedure

&AtClient
Procedure PaidOnChange ( Item )
	
	applyPaid ();
	
EndProcedure

&AtClient
Procedure applyPaid ()
	
	if ( not Object.Paid ) then
		Object.PaidBy = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Paid" );

EndProcedure
