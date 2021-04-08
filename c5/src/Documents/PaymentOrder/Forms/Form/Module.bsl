
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	setPrintPaymentContent ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Contract enable Object.Recipient <> Object.Company;
	|VAT enable filled ( Object.VATRate );
	|IncomeTax enable Object.IncomeTaxRate > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()

	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.BankAccount = DF.Pick ( Object.Company, "BankAccount" );
	setRecipient ();
	applyRecipient ();
	setPrintPaymentContent ();
	
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

// *****************************************
// *********** Group Form

&AtClient
Procedure RecipientOnChange ( Item )
	
	applyRecipient ();
	
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

	setUrgent ();
	calcVAT ();
	calcIncomeTax ();
	setPrintPaymentContent ();

EndProcedure

&AtServer
Procedure setUrgent () 

	if ( Object.Amount >= 5000 ) then
		Object.Urgent = true;
	endif;

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
