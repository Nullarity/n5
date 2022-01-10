&AtServer
var Env;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.SetCreator ( Object );
		initNew ();
	endif; 
	setAccuracy ();
	setLinks ();
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
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #Sales
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Invoice as Documents
	|where Documents.Shipment = &Ref
	|;
	|// #Transfers
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Transfer as Documents
	|where Documents.Shipment = &Ref
	|;
	|// #WriteOffs
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.WriteOff as Documents
	|where Documents.Base = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Sales, meta.Invoice ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Transfers, meta.Transfer ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOffs, meta.WriteOff ) );
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

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( ( EventName = Enum.MessageInvoiceIsSaved ()
			or EventName = Enum.MessageTransferIsSaved () )
		and DF.Pick ( Parameter, "Shipment" ) = Object.Ref ) then
		reread ();
	elsif ( EventName = Enum.MessageWriteOffIsSaved ()
		and DF.Pick ( Parameter, "Base" ) = Object.Ref ) then
		reread ();
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
Procedure OrganizationOnChange ( Item )
	
	applyOrganization ();

EndProcedure

&AtClient
Procedure applyOrganization ()
	
	Object.Stock = undefined;
	setReceiver ( Object.Organization );

EndProcedure

&AtClient
Procedure setReceiver ( Value )

	Object.Receiver = Value;

EndProcedure

&AtClient
Procedure StockOnChange ( Item )
	
	applyStock ();

EndProcedure

&AtClient
Procedure applyStock ()
	
	Object.Organization = undefined;
	setReceiver ( Object.Stock );

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

&AtClient
Procedure ItemsSeriesStartChoice ( Item, ChoiceData, StandardProcessing )
	
	SeriesForm.ShowBalances ( Item, ItemsRow.Item, Object.Warehouse, StandardProcessing );
	
EndProcedure
