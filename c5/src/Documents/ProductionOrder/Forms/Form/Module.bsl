&AtServer
var Base;
&AtServer
var Env;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		DocumentForm.Init ( Object );
		if ( Parameters.Basis = undefined ) then
			fillNew ();
		else
			Base = Parameters.Basis;
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.SalesOrder" )
				or baseType = Type ( "DocumentRef.InternalOrder" ) ) then
				fillByOrder ();
			endif; 
		endif; 
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	setLinks ();
	ItemPictures.RestoreGallery ( ThisObject );
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|PicturesPanel show PicturesEnabled;
	|ItemsShowPictures press PicturesEnabled
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company, Warehouse, Workshop" );
	if ( Object.Workshop.IsEmpty () ) then
		Object.Workshop = settings.Workshop;
	else
		Object.Company = DF.Pick ( Object.Workshop, "Owner" );
	endif;
	setDepartment ( Object );
	if ( Object.Warehouse.IsEmpty () ) then
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	if ( Object.Company.IsEmpty () ) then
		Object.Company = settings.Company;
	endif;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setDepartment ( Object )
	
	if ( Object.Workshop.IsEmpty () ) then
		Object.Department = undefined;
	else
		Object.Department = DF.Pick ( Object.Workshop, "Department" );
	endif;
	
EndProcedure

#region Filling

&AtServer
Procedure fillByOrder ()
	
	data = DF.Values ( Base, "Company, Warehouse" );
	Object.Company = data.Company;
	Object.Warehouse = data.Warehouse;
	Object.Workshop = Logins.Settings ( "Workshop" ).Workshop;
	setDepartment ( Object );
	table = getAllocation ();
	loadAllocation ( table );
	
EndProcedure 

&AtServer
Function getAllocation ()
	
	p = Filler.GetParams ();
	p.Report = "AllocationProduction";
	filters = new Array ();
	item = DC.CreateFilter ( "DocumentOrder" );
	item.RightValue = Base;
	filters.Add ( item );
	p.Filters = filters;
	return FillerSrv.GetData ( p );
	
EndFunction 

&AtServer
Procedure loadAllocation ( Table )
	
	provision = Enums.Provision.Directly;
	services = Object.Services;
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			docRow.Provision = provision;
			docRow.QuantityPkg = row.QuantityPkgBalance;
		endif;
		docRow.DocumentOrderRowKey = row.RowKey;
		docRow.Quantity = row.QuantityBalance;
	enddo; 
	
EndProcedure 

#endregion

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
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
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	s = "
	|// #Production
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Production as Documents
	|where Documents.ProductionOrder = &Ref
	|and not Documents.DeletionMark
	|order by Date
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not Object.Ref.IsEmpty () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Production, meta.Production ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.RefreshItemPictures () ) then
		ItemPictures.Refresh ( ThisObject );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		row.Item = Fields.Item;
		row.Package = Fields.Package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Provision = PredefinedValue ( "Enum.Provision.Free" );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsAllocateItems () ) then
		allocateItem ( SelectedValue, false );
	elsif ( operation = Enum.ChoiceOperationsAllocateServices () ) then
		allocateItem ( SelectedValue, true );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	itemsTable = Object.Items;
	for each selectedRow in Params.Items do
		row = itemsTable.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure addSelectedServices ( Params )
	
	services = Object.Services;
	for each selectedRow in Params.Services do
		row = services.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure allocateItem ( Params, Services )
	
	if ( Services ) then
		row = ServicesRow;
		table = Object.Services;
	else
		row = ItemsRow;
		table = Object.Items;
	endif; 
	result = Params.Result;
	FillPropertyValues ( row, result [ 0 ] );
	last = table.IndexOf ( row ) + 1;
	index = result.Ubound ();
	while ( index > 0 ) do
		row = table.Insert ( last );
		FillPropertyValues ( row, result [ index ] );
		index = index - 1;
	enddo; 
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.Services, "Item" );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not setRowKeys ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtServer
Function setRowKeys ( CurrentObject )
	
	error = not Catalogs.RowKeys.Set ( CurrentObject.Items, 1 );
	error = error or not Catalogs.RowKeys.Set ( CurrentObject.Services, 2 );
	return not error;
	
EndFunction

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageProductionOrderIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure WorkshopOnChange ( Item )
	
	setDepartment ( Object );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure AllocateItems ( Command )
	
	if ( ItemsRow = undefined ) then
		return;
	endif; 
	openAllocation ( false );
	
EndProcedure

&AtClient
Procedure openAllocation ( Services )
	
	if ( Services ) then
		rowIndex = Object.Services.IndexOf ( ServicesRow );
	else
		rowIndex = Object.Items.IndexOf ( ItemsRow );
	endif; 
	p = allocationParams ( rowIndex, Services );
	OpenForm ( "DataProcessor.Items.Form.ProvisionOrder", p, ThisObject );
	
EndProcedure 

&AtServer
Function allocationParams ( val RowIndex, val Services )
	
	p = new Structure ();
	p.Insert ( "Source", PickItems.GetParams ( ThisObject ) );
	p.Insert ( "Command", Enum.PickItemsCommandsAllocate () );
	p.Insert ( "Service", Services );
	tableRow = rowStructure ( RowIndex, Services );
	p.Insert ( "TableRow", tableRow );
	if ( Services ) then
		p.Insert ( "CountPackages", false );
	else
		p.Insert ( "CountPackages", DF.Pick ( tableRow.Item, "CountPackages" ) );
	endif; 
	return p;
	
EndFunction

&AtServer
Function rowStructure ( RowIndex, Services )
	
	table = ? ( Services, "Services", "Items" );
	row = new Structure ();
	for each item in Object.Ref.Metadata ().TabularSections [ table ].Attributes do
		row.Insert ( item.Name );
	enddo; 
	FillPropertyValues ( row, Object [ table ] [ RowIndex ] );
	return row;
	
EndFunction 

&AtClient
Procedure LoadOrders ( Command )
	
	Filler.Open ( fillingParams (), ThisObject );
	
EndProcedure

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "AllocationProduction";
	p.Filters = getFilters ();
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	warehouse = Object.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "Warehouse", warehouse ) );
	endif; 
	item = DC.CreateParameter ( "Asof" );
	item.Value = Periods.GetBalanceDate ( Object );
	item.Use = ( item.Value <> undefined );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	if ( Result.ClearTable ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
	endif; 
	loadAllocation ( table );
	return true;
	
EndFunction

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ShowHidePictures ( Command )
	
	togglePictures ();
	
EndProcedure

&AtServer
Procedure togglePictures ()
	
	ItemPictures.Toggle ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ResizeOnChange ( Item )
	
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure PictureOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ItemPictures.ClickProcessing ( EventData.Element.id, UUID );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	ShownProduct = ? ( ItemsRow = undefined, undefined, ItemsRow.Item );
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	OrderRows.ResetProvision ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	data = DF.Values ( ItemsRow.Item, "Package, Package.Capacity as Capacity" );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = Max ( data.Capacity, 1 );
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsProvisionOnChange ( Item )
	
	OrderRows.ResetOrder ( ItemsRow );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure AllocateServices ( Command )
	
	if ( ServicesRow = undefined ) then
		return;
	endif; 
	openAllocation ( true );
	
EndProcedure

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	ServicesRow.Description = DF.Pick ( ServicesRow.Item, "FullDescription" );
	
EndProcedure 
