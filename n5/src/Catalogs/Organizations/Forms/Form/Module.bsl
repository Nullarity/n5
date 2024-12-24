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
	
	init ();
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
		setRegistrationDate ();
	endif; 
	lockDescription ();
	OptionalProperties.Access ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	UseAI = Application.AI ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Lead show filled ( Object.Lead );
	|VendorPage show Object.Vendor;
	|CustomerPage show Object.Customer;
	|Write Write1 show empty ( Object.Ref );
	|CustomerContract VendorContract VendorItems enable filled ( Object.Ref );
	|PaymentAddress ShippingAddress show filled ( Object.Ref );
	|AddressInfo show empty ( Object.Ref );
	|Address Birthplace show Object.Individual and filled ( Object.Ref );
	|Wholesaler show Object.CustomerType = Enum.CustomerTypes.Branch;
	|Chain show Object.CustomerType = Enum.CustomerTypes.ChainRetailer;
	|FormDocumentSalesOrderNew FormDocumentInvoiceNew FormDocumentIOSheetNew show Object.Customer;
	|FormDocumentPurchaseOrderNew FormDocumentVendorInvoiceNew show Object.Vendor;
	|Description lock PropertiesData.ChangeName;
	|FullDescription lock PropertiesData.ChangeDescription;
	|OpenObjectUsage enable inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|ContactPerson PaymentContact ShippingContact hide Object.Individual or empty ( Object.Ref );
	|EntityGroup Government hide Object.Individual;
	|IndividualGroup1 IndividualGroup2 IndividualGroup3 show Object.Individual;
	|VATCode show Object.VATUse > 0;
	|WrongCode show WrongCode;
	|Fill hide Object.Individual;
	|Individual hide Object.Government;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.FillingText = "" ) then
		company = Parameters.Company;
		if ( not company.IsEmpty () ) then
			Object.Description = company.Description;
			Object.FullDescription = company.FullDescription;
			Object.CodeFiscal = company.CodeFiscal;
			if ( company.VAT ) then
				Object.VATUse = 1;
			endif;
		endif;
	else
		Object.Description = "";
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

&AtServer
Procedure fillByLead ()
	
	data = leadData ();
	Object.Customer = true;
	Object.Lead = Base;
	Object.Phone = data.BusinessPhone;
	Object.Email = data.Email;
	Object.Fax = data.Fax;
	Object.Web = data.Web;
	UploadLead = true;
	fillName ( data.OrganizationName );
	
EndProcedure

&AtServer
Function leadData ()
	
	data = DF.Values ( Base, "OrganizationName, BusinessPhone, Email, Fax, Web" );
	return data;
	
EndFunction

&AtServer
Procedure setRegistrationDate ()

	Object.RegistrationDate = CurrentSessionDate ();

EndProcedure

&AtServer
Procedure lockDescription ()
	
	if ( Application.AI () ) then
		Items.Description.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	endif;
	
EndProcedure

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
		OrganizationsForm.CreateContract ( CurrentObject, ref );
		saveAddress ( CurrentObject, ref );
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
Procedure saveAddress ( CurrentObject, Ref )
	
	if ( IsBlankString ( AddressInfo.Description ) ) then
		return;
	endif;
	address = FormAttributeToValue ( "AddressInfo" );
	address.Owner = Ref;
	address.DataExchange.Load = true;
	address.Write ();
	addressRef = address.Ref;
	CurrentObject.PaymentAddress = addressRef;
	CurrentObject.ShippingAddress = addressRef;	
	
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
Procedure CodeFiscalStartChoice ( Item, ChoiceData, ChoiceByAdding, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.OrganizationsClassifier.ChoiceForm", , Item );
	
EndProcedure

&AtClient
Procedure CodeFiscalAutoComplete ( Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing )
	
	if ( Object.Individual or StrLen ( Text ) < 3 ) then
		return;
	endif;
	StandardProcessing = false;
	ChoiceData = findOrganizations ( Text );
	
EndProcedure

&AtServerNoContext
Function findOrganizations ( val Text )
	
	return Catalogs.OrganizationsClassifier.GetChoiceData (
		new Structure ( "SearchString", Text )
	);
	
EndFunction

&AtClient
Procedure CodeFiscalChoiceProcessing ( Item, SelectedValue, AdditionalData, ChoiceByAdding, StandardProcessing )

	StandardProcessing = false;
	WaitForm.Open ( "startFillingByClassifier", SelectedValue, ThisObject );
	
EndProcedure

&AtClient
Procedure startFillingByClassifier ( Params, SelectedValue ) export

	fillByClassifier ( SelectedValue );
	WaitForm.Close ();	

EndProcedure

&AtServer
Procedure fillByClassifier ( val Classifier )
	
	applyClassifier ( Classifier );
	updateWarning ( ThisObject );
	Modified = true;
	
EndProcedure

&AtServer
Procedure applyClassifier ( Classifier )

	if ( Object.Individual ) then
		Object.Individual = false;
		applyIndividual ();
	endif;
	fields = DF.Values ( Classifier, "Code, Description, Address" );
	Object.CodeFiscal = fields.Code;
	if ( Object.Ref.IsEmpty () ) then
		fillAddress ( fields.Address );
	endif;
	fillName ( fields.Description );

EndProcedure

&AtServer
Procedure fillAddress ( String )
	
	if ( IsBlankString ( String ) ) then
		return;
	endif;
	disableAI = Left ( String, 1 ) = "#";
	if ( not disableAI and Application.AI () ) then
		FillPropertyValues ( AddressInfo, DataProcessors.AddressInfo.Get ( String ) );
	else
		AddressInfo.Description = ? ( disableAI, TrimAll ( Mid ( String, 2 ) ), String );
		AddressInfo.Manual = true;
	endif;

EndProcedure

&AtServer
Procedure fillName ( val String )
	
	if ( Left ( String, 1 ) = "#" ) then
		Object.FullDescription = TrimAll ( Mid ( String, 2 ) );
		if ( Object.Description = "" ) then
			Object.Description = Object.FullDescription;
		endif;
		return;
	endif;
	if ( Application.AI () ) then
		String = CoreLibrary.CyrillicToRomanian ( String );
		result = buildName ( String );
		Object.Description = Collections.Value ( result, "short_name" );
		Object.FullDescription = Collections.Value ( result, "full_name" );
	else
		Object.Description = String;
		Object.FullDescription = String;
	endif;
	Object.Description =
		CoreLibrary.RomanianToLatin ( TrimAll ( Object.Description ) );
	Object.FullDescription =
		CoreLibrary.RomanianToLatin ( TrimAll ( Object.FullDescription ) );

EndProcedure

&AtServer
Function buildName ( FullName )
	
	result = AI.BuildOrganizationName ( FullName );
	if ( result = undefined ) then
		return undefined;
	endif;
	name = Collections.Value ( result, "short_name", "" );
	if ( name = "" ) then
		return undefined;
	endif;
	if ( duplicate ( name ) ) then
		result.short_name = buildUnique ( name, FullName );
	endif;
	return result;
	
EndFunction

&AtServer
Function duplicate ( Name )
	
	found = Catalogs.Organizations.FindByDescription ( Name, true );
	return not found.IsEmpty () and found <> Object.Ref;

EndFunction

&AtServer
Function buildUnique ( ShortName, FullName )
	
	if ( Object.Individual ) then
		newName = ShortName + Output.IndividualSuffix ();
		if ( not duplicate ( newName ) ) then
			return newName;
		endif;
	endif;
	address = ? ( Object.Ref.IsEmpty (), AddressInfo, Object.PaymentAddress );
	parts = new Array ();
	parts.Add ( address.Country );
	parts.Add ( address.State );
	parts.Add ( address.City );
	parts.Add ( address.Street );
	parts.Add ( address.Number );
	name = new Array ();
	name.Add ( ShortName );
	for each part in parts do
		s = String ( part );
		if ( IsBlankString ( s ) ) then
			continue;
		endif;
		name.Add ( s );
		candidate = StrConcat ( name, ", " );
		if ( not duplicate ( candidate ) ) then
			return candidate;
		endif;
	enddo;
	result = AI.BuildOrganizationName ( FullName, true );
	newName = Collections.Value ( result, "short_name", "" );
	return ? ( newName = "", ShortName, newName );

EndFunction

&AtClient
Procedure CodeFiscalOpening ( Item, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.OrganizationsClassifier.ListForm",
		new Structure ( "CurrentRow", findOrganization ( Object.CodeFiscal ) ), ThisForm );
	
EndProcedure

&AtServerNoContext
Function findOrganization ( val Code )
	
	ref = Catalogs.OrganizationsClassifier.FindByCode ( Code );
	if ( ref.IsEmpty () ) then
		raise Output.OrganizationIsNotFound ();
	endif;
	return ref;
	
EndFunction

&AtClient
Procedure CodeFiscalOnChange ( Item )
	
	updateWarning ( ThisObject );
	
EndProcedure

&AtClient
Procedure AddressInfoOnChange ( Item )
	
	address = AddressInfo.Description;
	if ( not IsBlankString ( address ) ) then
		fillAddress ( address );
	endif;
	
EndProcedure

&AtClient
Procedure FullDescriptionOnChange ( Item )
	
	fillName ( Object.FullDescription );
	
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
Procedure GovernmentOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Government" );

EndProcedure

&AtClient
Procedure IndividualOnChange ( Item )
	
	applyIndividual ();	
	
EndProcedure

&AtServer
Procedure applyIndividual ()
	
	if ( Object.Individual ) then
		Object.Description = "";
		Object.FullDescription = "";
	else
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
	
	Object.FirstName = Title ( Object.FirstName );
	Object.LastName = Title ( Object.LastName );
	Object.Patronymic = Title ( Object.Patronymic );
	name = ContactsForm.FullName ( Object );
	Object.Description = name;
	Object.FullDescription = name;
	
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
