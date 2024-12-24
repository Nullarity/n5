&AtServer
var Env;
&AtClient
var ItemsRow;
&AtServer
var Base;
&AtServer
var BaseType;
&AtServer
var PurchaseOrderExists;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.SetCreator ( Object );
		initNew ();
		Base = Parameters.Basis;
		if ( Base <> undefined ) then
			fillByPurchaseOrder ();
		endif;
		updateChangesPermission ();
	endif; 
	setAccuracy ();
	setLinks ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure initNew ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		if ( Object.Warehouse.IsEmpty () ) then
			settings = Logins.Settings ( "Company, Warehouse" );
			Object.Company = settings.Company;
			Object.Warehouse = settings.Warehouse;
		else
			Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
		endif;
	else
		Object.Invoiced = false;
	endif;

EndProcedure

#region Filling

&AtServer
Procedure fillByPurchaseOrder ()
	
	setEnv ();
	sqlPurchaseOrder ();
	SQL.Perform ( Env );
	headerByPurchaseOrder ();
	table = FillerSrv.GetData ( fillingParams () );
	loadPurchaseOrders ( table );
	
EndProcedure 

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlPurchaseOrder ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Vendor as Vendor
	|from Document.PurchaseOrder as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByPurchaseOrder ()
	
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	Object.PurchaseOrder = Base;
	Object.Received = fields.Vendor;
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.ProposeClearing = Object.PurchaseOrder.IsEmpty ();
	report = "PurchaseOrderItems";
	p.Report = report;
	p.Filters = getFilters ( report );
	return p;
	
EndFunction

&AtServer
Function getFilters ( Report )
	
	filters = new Array ();
	filters.Add ( DC.CreateFilter ( "PurchaseOrder", Base ) );
	item = DC.CreateParameter ( "ReportDate" );
	item.Value = Catalogs.Calendar.GetDate ( Periods.GetBalanceDate ( Object ) );
	item.Use = not item.Value.IsEmpty ();
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Procedure loadPurchaseOrders ( Table )
	
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService ) then
			continue;
		endif; 
		docRow = itemsTable.Add ();
		FillPropertyValues ( docRow, row );
	enddo; 
	
EndProcedure 

#endregion

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "PurchaseOrder", Object.PurchaseOrder );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	PurchaseOrderExists = not Object.PurchaseOrder.IsEmpty ();
	selection = Env.Selection;
	if ( PurchaseOrderExists ) then
		s = "
		|// #PurchaseOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.PurchaseOrder as Documents
		|where Documents.Ref = &PurchaseOrder
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #VendorInvoices
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.VendorInvoice as Documents
	|where Documents.Receipt = &Ref
	|";
	selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( PurchaseOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.PurchaseOrders, meta.PurchaseOrder ) );
	endif;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorInvoices, meta.VendorInvoice ) );
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
	|Links show ShowLinks;
	|Warning show Object.Invoiced;
	|#s ItemsAdd hide Environment.MobileClient ();
	|ThisObject lock Object.Invoiced;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	assignKeys ( CurrentObject );
	
EndProcedure

&AtServer
Procedure assignKeys ( CurrentObject )
	
	if ( Object.PurchaseOrder.IsEmpty () ) then
		return;
	endif;
	search = new Structure ( "RowKey", Catalogs.RowKeys.EmptyRef () );
	itemsRows = CurrentObject.Items.FindRows ( search );
	if ( itemsRows.Count () = 0 ) then
		return;
	endif;
	orderRows = getOrderRows ();
	assignTableKeys ( itemsRows, orderRows );
	
EndProcedure

&AtServer
Function getOrderRows ()
	
	s = "
	|select Items.RowKey as Key, Items.Item as Item, Items.Feature as Feature
	|from Document.PurchaseOrder.Items as Items
	|where Items.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.PurchaseOrder );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure assignTableKeys ( Table, OrderRows )
	
	search = new Structure ( "Item, Feature" );
	for each row in Table do
		FillPropertyValues ( search, row );
		for each orderRow in OrderRows.FindRows ( search ) do
			row.RowKey = orderRow.Key;
			break; 
		enddo;
	enddo;
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.MessageVendorInvoiceIsSaved ()
		and DF.Pick ( Parameter, "Receipt" ) = Object.Ref ) then
		reread ();
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature, Series" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		row.Item = Fields.Item;
		row.Package = Fields.Package;
		row.Series = Fields.Series;
		row.Quantity = Fields.Quantity;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	
EndProcedure 

&AtServer
Procedure reread ()
	
	obj = Object.Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	setLinks ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange ( Item )
	
	setReceived ();

EndProcedure

&AtClient
Procedure setReceived ()
	
	Object.Received = Object.Vendor;

EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsSeriesStartChoice ( Item, ChoiceData, StandardProcessing )
	
	SeriesForm.ShowList ( Item, itemsRow.Item, StandardProcessing );
	                   
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )

	applyItem ();

EndProcedure

&AtClient
Procedure applyItem ()
	
	data = DF.Values ( ItemsRow.Item, "Package, Package.Capacity as Capacity" );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = ? ( data.Capacity = 0, 1, data.Capacity );
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )

	Computations.Packages ( ItemsRow );

EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )

	applyPackage ();

EndProcedure

&AtClient
Procedure applyPackage ()
	
	capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	ItemsRow.Capacity = capacity;
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )

	Computations.Units ( ItemsRow );

EndProcedure

