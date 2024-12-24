&AtServer
var Env;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	update ();
	
EndProcedure

&AtServer
Procedure update ()
	
	isApplied ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure isApplied ()
	
	s = "select top 1 1 from Document.Inventory.Items where Inventory = &Ref and Ref.Posted";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	SetPrivilegedMode ( true );
	InventoryApplied = not q.Execute ().IsEmpty ();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( isNew ( Object ) ) then
		DocumentForm.SetCreator ( Object );
		initNew ();
		updateChangesPermission ();
	endif; 
	setAccuracy ();
	setLinks ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	BarcodesEnabled = Options.Barcodes ();

EndProcedure

&AtClientAtServerNoContext
Function isNew ( Object )
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure initNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
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
	
	if ( isNew ( Object ) ) then
		return;
	endif; 
	s = "
	|// #Inventories
	|select Items.Ref as Document, Items.Ref.Date as Date, Items.Ref.Number as Number
	|from Document.Inventory.Items as Items
	|where Items.Inventory = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew ( Object ) ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventories, meta.Inventory ) );
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
	|Warning show InventoryApplied;
	|#s ItemsAdd hide Environment.MobileClient ();
	|ThisObject lock InventoryApplied;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( isNew ( Object )
		and BarcodesEnabled ) then
		AttachIdleHandler ( "openScanner", 0.1, true );
	endif;
	
EndProcedure

&AtClient
Procedure openScanner ()
	
	ScanForm.Open ( ThisObject, true );
	
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
	elsif ( EventName = Enum.MessageAccountingInventoryIsSaved () ) then
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
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		series = Fields.Series;
		row.Series = series;
		row.Quantity = Fields.Quantity;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Balance = getBalance ( item, Object.Warehouse, package, feature, series );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif;
	
EndProcedure 

&AtServerNoContext
Function getBalance ( val Item, val Warehouse, val Package, val Feature, val Series )
	
	s = "
	|select Balances.QuantityBalance as Balance
	|from AccumulationRegister.Items.Balance ( ,
	|	Item = &Item
	|	and Warehouse = &Warehouse
	|	and Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
	|	and Feature = &Feature
	|	and Series = &Series 
	|) as Balances
	|";
	q = new Query ( s );
	q.SetParameter ( "Item", Item );
	q.SetParameter ( "Warehouse", Warehouse );
	q.SetParameter ( "Package", Package );
	q.SetParameter ( "Feature", Feature );
	q.SetParameter ( "Series", Series );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Balance );
	
EndFunction

&AtServer
Procedure reread ()
	
	obj = Object.Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	setLinks ();
	update ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
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
	
	data = itemData ( ItemsRow.Item, Object.Warehouse );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = ? ( data.Capacity = 0, 1, data.Capacity );
	ItemsRow.Balance = data.Balance;
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtServerNoContext
Function itemData ( val Item, val Warehouse )
	
	data = new Structure ( "Package, Capacity, Balance" );
	fields = DF.Values ( Item, "Package, Package.Capacity as Capacity" );
	FillPropertyValues ( data, fields );
	data.Balance = getBalance ( item, Warehouse, fields.Package,
		Catalogs.Features.EmptyRef (), Catalogs.Series.EmptyRef () );
	return data;

EndFunction

&AtClient
Procedure ItemsSeriesOnChange ( Item )

	applySeries ();
	
EndProcedure

&AtClient
Procedure applySeries ()
	
	ItemsRow.Balance = getBalance ( ItemsRow.Item, Object.Warehouse,
		ItemsRow.Package, ItemsRow.Feature, ItemsRow.Series );
	
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
	
	data = packageData ( ItemsRow.Item, Object.Warehouse, ItemsRow.Package, ItemsRow.Feature, ItemsRow.Series );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Balance = data.Balance;
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function packageData ( val Item, val Warehouse, val Package, val Feature, val Series )
	
	data = new Structure ( "Capacity, Balance" );
	data.Capacity = DF.Pick ( Package, "Capacity", 1 );
	data.Balance = getBalance ( Item, Warehouse, Package, Feature, Series );
	return data;

EndFunction

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )

	Computations.Units ( ItemsRow );

EndProcedure
