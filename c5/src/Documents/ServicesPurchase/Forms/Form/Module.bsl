&AtServer
var Env;
&AtServer
var Base;
&AtServer
var BaseExists;
&AtServer
var BaseMetadata;
&AtServer
var ViewWriteOff;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setWarning ( ThisObject );
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClientAtServerNoContext
Procedure setWarning ( Form )
	
	items = Form.Items;
	if ( Form.Object.Range.IsEmpty () ) then
		items.Series.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
		items.FormNumber.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	else
		items.Series.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
		items.FormNumber.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		Base = Parameters.Basis;
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			Output.InteractiveCreationRestricted ();
			Cancel = true;
			return;
		endif; 
		DocumentForm.Init ( Object );
		fillByBase ();
		setRange ();
		setWarning ( ThisObject );
		updateChangesPermission ();
	endif;
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure fillByBase ()
	
	setEnv ();
	sqlBase ();
	SQL.Perform ( Env );
	headerByBase ();
	calculate ();
	
EndProcedure

&AtServer
Procedure calculate ()
	
	Object.Paid = Object.Amount + Object.Surcharges - Object.Discount;
	Object.IncomeTaxAmount = Object.Paid / 100 * Object.IncomeTaxRate;
	payment = Object.Paid - Object.IncomeTaxAmount;
	advance = Object.Advance;
	if ( payment > advance ) then
		Object.Total = payment - advance;
	else
		Object.Total = 0;
	endif; 
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlBase ()
	
	s = "
	|// @Fields
	|select Document.Ref as Base, Document.Company as Company, Document.Date as Date,
	|	isnull ( VendorServices.Amount, 0 ) as Amount
	|from Document.VendorInvoice as Document
	|	//
	|	// Items
	|	//
	|	left join (
	|		select Services.Ref as Ref, sum ( Services.Total ) as Amount
	|		from Document.VendorInvoice.Services as Services
	|		where Services.Ref = &Base
	|		group by Services.Ref
	|	) as VendorServices
	|	on VendorServices.Ref = Document.Ref
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByBase ()
	
	FillPropertyValues ( Object, Env.Fields );
	
EndProcedure 

&AtServer
Procedure setRange ()
	
	s = "
	|select allowed top 1 Documents.Range as Range
	|from Document.ItemsPurchase as Documents
	|where Documents.Company = &Company
	|and Documents.Creator = &Creator
	|and not Documents.DeletionMark
	|order by Documents.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Creator", Object.Creator );
	table = q.Execute ().Unload ();
	Object.Range = ? ( table.Count () = 0, undefined, table [ 0 ].Range );
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Base", Object.Base );
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	BaseExists = ValueIsFilled ( Object.Base );
	if ( BaseExists ) then
		BaseMetadata = Metadata.FindByType ( TypeOf ( Object.Base ) );
		s = "
		|// #Base
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + BaseMetadata.Name + " as Documents
		|where Documents.Ref = &Base
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	meta = Metadata.Documents;
	ViewWriteOff = AccessRight ( "View", meta.WriteOffForm );
	if ( ViewWriteOff ) then
		s = "
		|// #WriteOffs
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.WriteOffForm as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif;
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( BaseExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Base, BaseMetadata ) );
	endif;
	if ( not isNew () ) then
		if ( ViewWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOffs, meta.WriteOffForm ) );
		endif;
	endif;
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Company Date Amount lock filled ( Object.Base );
	|GroupHeader PageMain PageMore unlock Object.Status = Enum.FormStatuses.Saved;
	|Warning hide Object.Status = Enum.FormStatuses.Saved;
	|Links show ShowLinks;
	|Series FormNumber show filled ( Object.Range );
	|Number show empty ( Object.Range );
	|IncomeTaxGroup show filled ( Object.IncomeTax );
	|" );
	Appearance.Read ( ThisObject, rules );

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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	Appearance.Apply ( ThisObject, "Object.Status" );

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageServicesPurchaseIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure RangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseRange ( Item );
	
EndProcedure

&AtClient
Procedure chooseRange ( Item )
	
	filter = new Structure ();
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and not Object.Ref.IsEmpty () ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	OpenForm ( "Catalog.Ranges.Form.Balances", new Structure ( "Filter", filter ), Item );
	
EndProcedure

&AtClient
Procedure RangeOnChange ( Item )
	
	setWarning ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Range" );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	calculate ();
	
EndProcedure

&AtClient
Procedure SurchargesOnChange ( Item )
	
	calculate ();
	
EndProcedure

&AtClient
Procedure DiscountOnChange ( Item )
	
	calculate ();		
	
EndProcedure

&AtClient
Procedure IncomeTaxOnChange ( Item )
	
	applyIncomeTax ();
	
EndProcedure

&AtClient
Procedure applyIncomeTax ()
	
	if ( Object.IncomeTax.IsEmpty () ) then
		Object.IncomeTaxRate = 0;
	endif;
	calculate ();
	Appearance.Apply ( ThisObject, "Object.IncomeTax" );		
	
EndProcedure

&AtClient
Procedure IncomeTaxRateOnChange(Item)
	
	calculate ();	
	
EndProcedure

&AtClient
Procedure AdvanceOnChange ( Item )
	
	calculate ();
	
EndProcedure
