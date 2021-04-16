&AtServer
var Base;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Options.ApplyOrganization ( ThisObject, Object.Ref );
	filterByVendor ();
	initPhones ();
	updateWarning ( ThisObject );
	OptionalProperties.Load ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure filterByVendor ()
	
	if ( not Object.Vendor ) then
		return;
	endif; 
	DC.ChangeFilter ( VendorItems, "Vendor", Object.Ref, true );
	
EndProcedure
 
&AtServer
Procedure initPhones ()
	
	PhoneTemplates.Set ( ThisObject, "Phone, Fax" );

EndProcedure 

&AtClientAtServerNoContext
Procedure updateWarning ( Form )
	
	object = Form.Object;
	code = object.CodeFiscal;
	if ( code = "" ) then
		Form.WrongCode = false;		
	else
		Form.WrongCode = codeExists ( code, object.Ref );		
	endif;
	Appearance.Apply ( Form, "WrongCode" );
	
EndProcedure

&AtServerNoContext
Function codeExists ( val Code, val Ref )
	
	s = "
	|select top 1 1
	|from Catalog.Organizations as Organizations
	|where Organizations.CodeFiscal = &Code
	|and Organizations.Ref <> &Ref
	|and not Organizations.DeletionMark";
	q = new Query ( s );
	q.SetParameter ( "Code", Code );
	q.SetParameter ( "Ref", Ref );
	SetPrivilegedMode ( true );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		Options.Organization ( ThisObject, Object.Ref );
		OptionalProperties.Load ( ThisObject );
		initPhones ();
		filterByVendor ();
		if ( Parameters.Basis = undefined ) then
			fillNew ();
		else
			Base = Parameters.Basis;
			type = TypeOf ( Base );
			if ( type = Type ( "CatalogRef.Leads" ) ) then
				fillByLead ();
			endif;
		endif;
		updateWarning ( ThisObject );
	endif; 
	OptionalProperties.Access ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Lead show filled ( Object.Lead );
	|VendorPage show Object.Vendor;
	|CustomerPage show Object.Customer;
	|Write Write1 show empty ( Object.Ref );
	|Address Birthplace PaymentAddress PaymentContact ShippingAddress ShippingContact ContactPerson CustomerContract VendorContract VendorItems enable filled ( Object.Ref );
	|Wholesaler show Object.CustomerType = Enum.CustomerTypes.Branch;
	|Chain show Object.CustomerType = Enum.CustomerTypes.ChainRetailer;
	|FormDocumentSalesOrderNew FormDocumentInvoiceNew FormDocumentIOSheetNew show Object.Customer;
	|FormDocumentPurchaseOrderNew FormDocumentVendorInvoiceNew show Object.Vendor;
	|Description lock PropertiesData.ChangeName;
	|FullDescription lock PropertiesData.ChangeDescription;
	|OpenObjectUsage enable inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|EntityGroup ContactPerson PaymentContact ShippingContact hide Object.Individual;
	|IndividualGroup1 IndividualGroup2 IndividualGroup3 Address Birthplace show Object.Individual;
	|VATCode show Object.VATUse > 0;
	|WrongCode show WrongCode;
	|Fill hide Object.Individual
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.FillingText <> "" ) then
		setFullDescription ( ThisObject );
	else
		company = Parameters.Company;
		if ( not company.IsEmpty () ) then
			Object.Description = company.Description;
			Object.FullDescription = company.FullDescription;
			Object.CodeFiscal = company.CodeFiscal;
			if ( company.VAT ) then
				Object.VATUse = 1;
			endif;
		endif;
	endif; 
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		Object.Contact = undefined;
		Object.Address = undefined;
		Object.Birthplace = undefined;
		Object.CustomerContract = undefined;
		Object.VendorContract = undefined;
		Object.PaymentAddress = undefined;
		Object.PaymentContact = undefined;
		Object.ShippingAddress = undefined;
		Object.ShippingContact = undefined;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setFullDescription ( Form )
	
	object = Form.Object;
	object.FullDescription = object.Description;
	
EndProcedure 

&AtServer
Procedure fillByLead ()
	
	data = leadData ();
	Object.Customer = true;
	Object.Lead = Base;
	Object.Description = data.OrganizationName;
	setFullDescription ( ThisObject );
	Object.Phone = data.BusinessPhone;
	Object.Email = data.Email;
	Object.Fax = data.Fax;
	Object.Web = data.Web;
	UploadLead = true;
	
EndProcedure

&AtServer
Function leadData ()
	
	data = DF.Values ( Base, "OrganizationName, BusinessPhone, Email, Fax, Web" );
	return data;
	
EndFunction

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not OptionalProperties.Check ( ThisObject ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	ref = getReference ( CurrentObject );
	if ( Object.Ref.IsEmpty () ) then
		createContract ( CurrentObject, ref );
	endif;
	if ( WriteParameters.Property ( "Fields" ) ) then
		loadFields ( CurrentObject, ref, WriteParameters.Fields );
	endif;
	
EndProcedure

&AtServer
Function getReference ( CurrentObject )
	
	if ( CurrentObject.IsNew () ) then
		CurrentObject.SetNewObjectRef ( Catalogs.Organizations.GetRef ( new UUID () ) );
		return CurrentObject.GetNewObjectRef ();
	else
		return CurrentObject.Ref;
	endif;
	
EndFunction

&AtServer
Procedure createContract ( CurrentObject, Ref )
	
	SetPrivilegedMode ( true );
	customer = CurrentObject.Customer;
	vendor = CurrentObject.Vendor;
	settings = Logins.Settings ( "Company" );
	obj = Catalogs.Contracts.CreateItem ();
	Metafields.Constructor ( obj );
	obj.DataExchange.Load = true;
	obj.Owner = ref;
	obj.Description = Output.General ();
	obj.Company = settings.Company;
	obj.Currency = Application.Currency ();
	obj.Customer = customer;
	obj.Vendor = vendor;
	if ( customer ) then
		obj.CustomerTerms = Constants.Terms.Get ();
		obj.CustomerPayment = Constants.PaymentMethod.Get ();
		obj.CustomerVATAdvance = getVATAdvance ();
	endif;
	if ( vendor ) then
		obj.VendorTerms = Constants.VendorTerms.Get ();
		obj.VendorPayment = Constants.VendorPaymentMethod.Get ();
		obj.VendorVATAdvance = getVATAdvance ();
	endif; 
	obj.Write ();
	if ( customer ) then
		CurrentObject.CustomerContract = obj.Ref;
	endif; 
	if ( vendor ) then
		CurrentObject.VendorContract = obj.Ref;
	endif; 
	
EndProcedure 

Function getVATAdvance ()
	
	s = "
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( ,
	|	Parameter = value ( ChartOfCharacteristicTypes.Settings.VATAdvance )
	|) as Settings
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Value );

EndFunction

&AtServer
Procedure loadFields ( CurrentObject, Ref, Data )

	SetPrivilegedMode ( true );
	CurrentObject.Description = Data.Description;
	CurrentObject.FullDescription = Data.FullDescription;
	code = Data.VATCode;
	CurrentObject.VATCode = code;
	CurrentObject.VATUse = ? ( code = "", 0, 1 );
	createContact ( CurrentObject, Ref, Data );
	createAddress ( CurrentObject, Ref, Data );
		
EndProcedure

&AtServer
Procedure createContact ( CurrentObject, Ref, Data )
	
	lastName = Data.LastName;
	if ( lastName = undefined ) then
		return;
	endif;
	if ( CurrentObject.Contact.IsEmpty () ) then
		obj = Catalogs.Contacts.CreateItem ();
	else
		obj = CurrentObject.Contact.GetObject ();
	endif;
	obj.Owner = Ref;
	obj.Gender = Enums.Sex.Male;
	obj.LastName = lastName;
	obj.FirstName = Data.FirstName;
	obj.Patronymic = Data.Patronymic;
	obj.Description = ContactsForm.FullName ( obj );
	obj.ContactType = Catalogs.ContactTypes.Director;
	obj.DataExchange.Load = true;
	obj.Write ();
	contact = obj.Ref;
	CurrentObject.Contact = contact;
	CurrentObject.PaymentContact = contact;
	CurrentObject.ShippingContact = contact;	
	
EndProcedure

&AtServer
Procedure createAddress ( CurrentObject, Ref, Data )
	
	address = Data.Address;
	if ( address = undefined ) then
		return;
	endif;
	if ( CurrentObject.PaymentAddress.IsEmpty () ) then
		obj = Catalogs.Addresses.CreateItem ();
	else
		obj = CurrentObject.PaymentAddress.GetObject ();
	endif;
	obj.Owner = Ref;
	obj.Manual = true;
	obj.Address = address;
	obj.Description = address;
	obj.DataExchange.Load = true;
	obj.Write ();
	address = obj.Ref;
	CurrentObject.PaymentAddress = address;
	CurrentObject.ShippingAddress = address;	
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( UploadLead ) then
		uploadLead ( CurrentObject.Ref );
	else
		inheritAddresses ( CurrentObject );
	endif;
	
EndProcedure

&AtServer
Procedure uploadLead ( Ref )
	
	contacts = Catalogs.Contacts.Select ( , Object.Lead );
	while ( contacts.Next () ) do
		obj = contacts.GetObject ();
		newObj = obj.Copy ();
		newObj.Owner = Ref;
		newObj.Write ();
		newContact = newObj.Ref;
		addresses = Catalogs.Addresses.Select ( , contacts.Ref );
		while ( addresses.Next () ) do
			obj = addresses.GetObject ();
			newObj = obj.Copy ();
			newObj.Owner = Ref;
			newObj.Write ();
			newObj = obj.Copy ();
			newObj.Owner = newContact;
			newObj.Write ();
		enddo;
	enddo;
	UploadLead = false;
	
EndProcedure

&AtServer
Procedure inheritAddresses ( CurrentObject )
	
	company = Parameters.Company;
	inherit = not company.IsEmpty () and Object.Ref.IsEmpty ();
	if ( not inherit ) then
		return;
	endif; 
	paymentAddress = company.PaymentAddress;
	CurrentObject.PaymentAddress = cloneAddress ( paymentAddress, CurrentObject );
	shippingAddress = company.ShippingAddress;
	if ( shippingAddress = paymentAddress ) then
		CurrentObject.ShippingAddress = CurrentObject.PaymentAddress;
	else
		CurrentObject.ShippingAddress = cloneAddress ( shippingAddress, CurrentObject );
	endif; 
	
EndProcedure 

&AtServer
Function cloneAddress ( Address, CurrentObject )
	
	if ( address.IsEmpty () ) then
		return undefined;
	endif; 
	obj = address.Copy ();
	obj.Owner = CurrentObject.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterByVendor ();
	Options.ApplyOrganization ( ThisObject, Object.Ref );
	Appearance.Apply ( ThisObject );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CodeFiscalOnChange ( Item )
	
	updateWarning ( ThisObject );
	
EndProcedure

&AtClient
Procedure Fill ( Command )	
	
	if ( not Forms.Check ( ThisObject, "CodeFiscal" ) ) then
		return;	
	endif;
	if ( not Object.Ref.IsEmpty () ) then
		OutputCont.UpdateByCodeFiscal ( ThisObject );
		return;
	endif;
	if ( WrongCode ) then
		OutputCont.UpdateByWrongCodeFiscal ( ThisObject );
		return;		
	endif;
	fillByCodeFiscal ();
		
EndProcedure

&AtClient
Procedure UpdateByCodeFiscal ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	fillByCodeFiscal ()
	
EndProcedure

&AtClient
Procedure fillByCodeFiscal ()
	
	LoadKey = UUID;
	runFilling ();
	Progress.Open ( LoadKey, ThisObject, new NotifyDescription ( "LoadingComplete", ThisObject ), true );
	
EndProcedure

&AtServer
Procedure runFilling ()
	
	p = DataProcessors.LoadOrganization.GetParams();
	p.CodeFiscal = Object.CodeFiscal;
	AddressLoad = PutToTempStorage ( undefined, UUID );
	p.Address = AddressLoad;
	args = new Array ();
	args.Add ( "LoadOrganization" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, LoadKey, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure LoadingComplete ( Result, Params ) export

	if ( Result = undefined ) then
		return;
	endif;
	applyFilling ();	
	
EndProcedure

&AtServer
Procedure applyFilling ()
	
	result = GetFromTempStorage ( AddressLoad );
	if ( result = undefined ) then
		OutputCont.OrganizationNotFound ();
	else
		Write ( new Structure ( "Fields", result ) );	
	endif;
		
EndProcedure

&AtClient
Procedure ParentOnChange ( Item )
	
	applyParent ();
	
EndProcedure

&AtServer
Procedure applyParent ()
	
	OptionalProperties.Load ( ThisObject );
	
EndProcedure 

&AtClient
Procedure DescriptionOnChange ( Item )
	
	setFullDescription ( ThisObject );
	
EndProcedure

&AtClient
Procedure PaymentAddressOnChange ( Item )
	
	setShippingAddress ();
	
EndProcedure

&AtClient
Procedure setShippingAddress ()
	
	address = Object.PaymentAddress;
	if ( address.IsEmpty () ) then
		return;
	endif; 
	if ( Object.ShippingAddress.IsEmpty () ) then
		Object.ShippingAddress = address;
	endif; 

EndProcedure 

&AtClient
Procedure ContactPersonOnChange ( Item )
	
	applyContact ();
	
EndProcedure

&AtClient
Procedure applyContact ()
	
	if ( Object.Contact.IsEmpty () ) then
		return;
	endif; 
	if ( Object.PaymentContact.IsEmpty () ) then
		Object.PaymentContact = Object.Contact;
	endif; 
	if ( Object.ShippingContact.IsEmpty () ) then
		Object.ShippingContact = Object.Contact;
	endif; 
	
EndProcedure 

&AtClient
Procedure PaymentContactOnChange ( Item )
	
	setShippingContact ();
	
EndProcedure

&AtClient
Procedure setShippingContact ()
	
	if ( Object.ShippingContact.IsEmpty () ) then
		Object.ShippingContact = Object.PaymentContact;
	endif; 
	
EndProcedure 

&AtClient
Procedure CustomerOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Customer" );
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	
EndProcedure

&AtServer
Procedure applyVendor ()
	
	filterByVendor ();
	Appearance.Apply ( ThisObject, "Object.Vendor" );	
	
EndProcedure 

&AtClient
Procedure IndividualOnChange ( Item )
	
	applyIndividual ();	
	
EndProcedure

&AtServer
Procedure applyIndividual ()
	
	if ( not Object.Individual ) then
		Object.FirstName = "";
		Object.LastName = "";
		Object.Patronymic = "";
		Object.Birthday = undefined;
		Object.Gender = undefined;
		Object.Issued = undefined;
		Object.IssuedBy = "";
		Object.SIN = "";
		Object.Policy = "";
		Object.Birthplace = undefined;
		Object.Series = "";
		Object.Number = "";
		Object.ValidTo = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Individual" );	
	
EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )

	applyVAT ();
	
EndProcedure

&AtClient
Procedure applyVAT ()
	
	if ( Object.VATUse = 0 ) then
		Object.VATCode = "";
	endif;
	Appearance.Apply ( ThisObject, "Object.VATUse" );	

EndProcedure

&AtClient
Procedure CustomerTypeOnChange ( Item )
	
	applyCustomerType ();
	
EndProcedure

&AtServer
Procedure applyCustomerType ()
	
	if ( Object.CustomerType <> Enums.CustomerTypes.Branch ) then
		Object.Wholesaler = undefined;
	endif;
	if ( Object.CustomerType <> Enums.CustomerTypes.ChainRetailer ) then
		Object.Chain = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.CustomerType" );
	
EndProcedure 

&AtClient
Procedure PhoneStartChoice ( Item, ChoiceData, StandardProcessing )
	
	PhoneTemplates.Choice ( ThisObject, Item );

EndProcedure

&AtClient
Procedure NameOnChange ( Item )
	
	setName ( Object );		
	
EndProcedure

&AtClientAtServerNoContext
Procedure setName ( Object )
	
	Object.Description = ContactsForm.FullName ( Object );
	
EndProcedure

// *****************************************
// *********** Page ApprovalListPage

&AtClient
Procedure ApprovalListOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow ) then
		return;
	endif; 
	setPriority ( Item.CurrentData );
	
EndProcedure

&AtClient
Procedure setPriority ( Row )
	
	Row.Priority = Row.LineNumber;
	
EndProcedure 

// *****************************************
// *********** Page Properties

&AtClient
Procedure ObjectUsageOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ObjectUsage" );
	
EndProcedure

&AtClient
Procedure OpenObjectUsage ( Command )
	
	OptionalProperties.Open ( ThisObject, PredefinedValue ( "Enum.PropertiesScope.Item" ), Object.ObjectUsage );
	
EndProcedure

&AtClient
Procedure PropertiesChanged ( Changed, Form ) export
	
	updateProperties ();
	
EndProcedure 

&AtServer
Procedure updateProperties ()
	
	OptionalProperties.Load ( ThisObject );
	
EndProcedure 

&AtClient
Procedure PropertyOnChange ( Item ) export
	
	OptionalProperties.ApplyConditions ( ThisObject, Item );
	OptionalProperties.BuildDescription ( ThisObject );
	OptionalProperties.ChangeHost ( ThisObject, Item );
	
EndProcedure 
