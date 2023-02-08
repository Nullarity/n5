&AtClient
var RefillItemsTable;
&AtClient
var RefillPriceGroupsTable;
&AtServer
var Base;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readTables ( CurrentObject.Ref );
	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure readTables ( Ref )
	
	fillPricesAndBuildTables ( Ref );
	readItemsTable ();
	readPriceGroupsTable ();
	setItemsTableRowsCount ( ThisObject );
	setPriceGroupsTableRowsCount ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillPricesAndBuildTables ( MarkedPricesRef = undefined )

	fillPrices ( MarkedPricesRef );
	buildItemsAndPriceGroupsTable ( "ItemsTable" );
	buildItemsAndPriceGroupsTable ( "PriceGroupsTable" );
	
EndProcedure

&AtServer
Procedure fillPrices ( MarkedPricesRef = undefined )
	
	env = new Structure ();
	SQL.Init ( env );
	sqlPricesAndPriceGroups ( Env );
	env.Q.SetParameter ( "Company", Object.Company );
	env.Q.SetParameter ( "Ref", MarkedPricesRef );
	SQL.Perform ( env );
	ItemsPricesTable.Load ( env.Prices );
	PriceGroupsPricesTable.Load ( env.PriceGroups );
	
EndProcedure 

&AtServer
Procedure sqlPricesAndPriceGroups ( Env )
	
	s = "
	|// #Prices
	|select allowed List.Ref as Prices, List.BasePrices as BasePrices,
	|	case when ( SetupPrices.Prices is null ) then false else true end as Use
	|from Catalog.Prices as List
	|	//
	|	// SetupPrices
	|	//
	|	left join Document.SetupPrices.ItemsPrices as SetupPrices
	|	on SetupPrices.Ref = &Ref
	|	and SetupPrices.Prices = List.Ref
	|where ( not List.DeletionMark or SetupPrices.Prices is not null )
	|and List.Owner = &Company
	|and Pricing <> value ( Enum.Pricing.Percent )
	|and Pricing <> value ( Enum.Pricing.Group )
	|and Pricing <> value ( Enum.Pricing.Cost )
	|order by List.Code
	|;
	|// #PriceGroups
	|select allowed List.Ref as Prices, List.BasePrices as BasePrices,
	|	case when ( SetupPrices.Prices is null ) then false else true end as Use
	|from Catalog.Prices as List
	|	//
	|	// SetupPrices
	|	//
	|	left join Document.SetupPrices.PriceGroupsPrices as SetupPrices
	|	on SetupPrices.Ref = &Ref
	|	and SetupPrices.Prices = List.Ref
	|where ( not List.DeletionMark or SetupPrices.Prices is not null )
	|and List.Owner = &Company
	|and Pricing = value ( Enum.Pricing.Group )
	|order by List.Code
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure buildItemsAndPriceGroupsTable ( TableName )

	meta = Metadata.Documents.SetupPrices.TabularSections;
	if ( TableName = "ItemsTable" ) then
		columnType = meta.Items.Attributes.PriceOrPercent.Type;
		tablePrices = ItemsPricesTable;
	else
		columnType = meta.PriceGroups.Attributes.Percent.Type;
		tablePrices = PriceGroupsPricesTable;
	endif; 
	attrArray = GetAttributes ( TableName );
	existedAttributes = new Array ();
	for each attr in attrArray do
		existedAttributes.Add ( attr.Name );
	enddo; 
	toRemoveAttributes = new Array ();
	toAddAttributes = new Array ();
	columnsItemsTable = new Array ();
	pricesByTableName = new Structure ();
	for each priceRow in tablePrices do
		columnName = columnByRef ( priceRow.Prices );
		foundIndex = existedAttributes.Find ( columnName );
		columnFound = ( foundIndex <> undefined );
		if ( not priceRow.Use ) then
			if ( columnFound ) then
				toRemoveAttributes.Add ( TableName + "." + columnName );
			endif; 
		else
			if ( not columnFound ) then
				toAddAttributes.Add ( new FormAttribute ( columnName, columnType, TableName, "" + priceRow.Prices, true ) );
			endif;
			columnsItemsTable.Add ( columnName );
			pricesByTableName.Insert ( columnName, priceRow.Prices );
		endif; 
	enddo; 
	ChangeAttributes ( toAddAttributes, toRemoveAttributes );
	counter = Items [ TableName ].ChildItems.Count () - 1;
	while ( counter >= 0 ) do
		formFiled = Items [ TableName ].ChildItems [ counter ];
		if ( Left ( formFiled.Name, 1 ) = "_" ) then
			Items.Delete ( formFiled );
		endif; 
		counter = counter - 1;
	enddo; 
	for each column in columnsItemsTable do
		field = Items.Add ( column, Type ( "FormField" ), Items [ TableName ] );
		field.DataPath = TableName + "." + column;
		field.Type = FormFieldType.InputField;
		field.Enabled = true;
		field.Visible = true;
	enddo; 
	if ( TableName = "ItemsTable" ) then
		PricesByItems = pricesByTableName;
	else
		PricesByGroups = pricesByTableName;
	endif; 
	
EndProcedure

&AtServer
Function columnByRef ( Ref )
	
	return "_" + StrReplace ( Ref.UUID (), "-" , "" );
	
EndFunction

&AtServer
Procedure readItemsTable ()
	
	ItemsTable.Clear ();
	cache = new Map ();
	last = -1;
	for each row in Object.Items do
		item = row.Item;
		i = cache [ item ];
		if ( i = undefined ) then
			ItemsTable.Add ();
			last = last + 1;
			cache [ item ] = last;
			i = last;
		endif;
		columnName = columnByRef ( row.Prices );
		tableRow = ItemsTable [ i ];
		tableRow.Item = item;
		tableRow.Package = row.Package;
		tableRow.Feature = row.Feature;
		tableRow [ columnName ] = row.PriceOrPercent;
	enddo; 
	
EndProcedure 

&AtServer
Procedure readPriceGroupsTable ()
	
	PriceGroupsTable.Clear ();
	i = 0;
	count = Object.PriceGroupsPrices.Count ();
	for each rowPriceGroups in Object.PriceGroups do
		if ( i = 0 ) or ( i > count ) then
			rowPriceGroupTable = PriceGroupsTable.Add ();
			i = 1;
		endif; 
		columnName = columnByRef ( rowPriceGroups.Prices );
		rowPriceGroupTable.PriceGroup = rowPriceGroups.PriceGroup;
		rowPriceGroupTable [ columnName ] = rowPriceGroups.Percent;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then 
		DocumentForm.Init ( Object );
		if ( Parameters.Basis = undefined ) then
			fillNew ();
		else
			buildItemsAndPriceGroupsTable ( "PriceGroupsTable" );
			baseType = TypeOf ( Parameters.Basis );
			if ( baseType = Type ( "DocumentRef.VendorInvoice" ) ) then
				fillByItemsReceipt ();
			endif;
		endif;
		updateChangesPermission ();
	endif;
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );

EndProcedure

#region Filling

&AtServer
Procedure fillByItemsReceipt ()
	
	SQL.Init ( Base );
	Base.Insert ( "Ref", Parameters.Basis );
	getItemsReceiptData ();
	if ( Base.Fields.Prices.IsEmpty () ) then
		raise Output.UndefinedCostPriceType ();
	endif;
	fillFieldsByBase ();
	fillITablesByBase ();
	fillPrices ();
	markVendorPrices ();
	buildItemsAndPriceGroupsTable ( "ItemsTable" );
	readItemsTable ();
	
EndProcedure

&AtServer
Procedure getItemsReceiptData ()
	
	s = "
	|select case when Document.Prices = value ( Catalog.Prices.EmptyRef )
	|			then Document.Company.CostPrices
	|			else Document.Prices
	|		end as Prices
	|into DocumentPrices
	|from Document.VendorInvoice as Document
	|where Document.Ref = &Ref
	|;
	|// @Fields
	|select Document.Company as Company, Document.Date as Date, DocumentPrices.Prices as Prices, Document.Vendor as Vendor,
	|	Document.Warehouse as Warehouse, DocumentPrices.Prices.Detail as PricesDetail
	|from Document.VendorInvoice as Document, DocumentPrices as DocumentPrices
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select 0 as Table, min ( Items.LineNumber ) as LineNumber, Items.Item as Item,
	|	Items.Package as Package, Items.Feature as Feature, Items.Price as PriceOrPercent,
	|	DocumentPrices.Prices as Prices
	|from Document.VendorInvoice.Items as Items
	|	//
	|	// DocumentPrices
	|	//
	|	left join DocumentPrices as DocumentPrices
	|	on true
	|where Items.Ref = &Ref
	|group by Items.Item, Items.Package, Items.Feature, Items.Price, DocumentPrices.Prices
	|union all
	|select 1, min ( Services.LineNumber ), Services.Item, null, Services.Feature, Services.Price, DocumentPrices.Prices
	|from Document.VendorInvoice.Services as Services
	|	//
	|	// DocumentPrices
	|	//
	|	left join DocumentPrices as DocumentPrices
	|	on true
	|where Services.Ref = &Ref
	|group by Services.Item, Services.Feature, Services.Price, DocumentPrices.Prices
	|order by Table, LineNumber
	|";
	Base.Selection.Add ( s );
	Base.Q.SetParameter ( "Ref", Base.Ref );
	SQL.Perform ( Base );
	
EndProcedure 

&AtServer
Procedure fillFieldsByBase ()
	
	Object.Company = Base.Fields.Company;
	Object.Date = Base.Fields.Date;
	
EndProcedure 

&AtServer
Procedure fillITablesByBase ()
	
	Object.Items.Load ( Base.Items );
	if ( Base.Fields.PricesDetail = Enums.PriceDetails.ItemAndOrganization
		or Base.Fields.PricesDetail = Enums.PriceDetails.ItemAndWarehouseAndOrganization ) then
		row = Object.Organizations.Add ();
		row.Prices = Base.Fields.Prices;
		row.Organization = Base.Fields.Vendor;
	endif; 
	if ( Base.Fields.PricesDetail = Enums.PriceDetails.ItemAndWarehouse
		or Base.Fields.PricesDetail = Enums.PriceDetails.ItemAndWarehouseAndOrganization ) then
		row = Object.Warehouses.Add ();
		row.Prices = Base.Fields.Prices;
		row.Warehouse = Base.Fields.Warehouse;
	endif; 
	
EndProcedure 

&AtServer
Procedure markVendorPrices ()
	
	rows = ItemsPricesTable.FindRows ( new Structure ( "Prices", Base.Fields.Prices ) );
	if ( rows.Count () > 0 ) then
		rows [ 0 ].Use = true;
	endif; 
	
EndProcedure 

#endregion

&AtServer
Procedure fillNew ()
	
	Object.Date = BegOfDay ( CurrentDate () );
	if ( Parameters.CopyingValue.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
		fillPricesAndBuildTables ();
	else
		readTables ( Parameters.CopyingValue.Ref );
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

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( ItemsTable, "Item" );
	Forms.DeleteLastRow ( PriceGroupsTable, "PriceGroup" );
	Forms.DeleteLastRow ( Object.Organizations, "Prices" );
	Forms.DeleteLastRow ( Object.Warehouses, "Prices" );
	if ( RefillItemsTable ) then
		buildItemsAndPriceGroupsTable ( "ItemsTable" );
		RefillItemsTable = false;
	endif;
	if ( RefillPriceGroupsTable ) then
		buildItemsAndPriceGroupsTable ( "PriceGroupsTable" );
		RefillPriceGroupsTable = false;
	endif; 
	Cancel = not uploadItemsTable ();
	
EndProcedure

&AtServer
Function uploadItemsTable ()

	error = not checkItemsTable ();
	error = not checkPriceGroupsTable () or error;
	error = not checkItemDoubles () or error;
	error = not checkPriceGroupsDoubles () or error;
	error = not checkSelectedPrices () or error;
	if ( error ) then
		return false;
	endif; 
	uploadItemsPrices ();
	uploadPriceGroupsPrices ();
	return true;
	
EndFunction

&AtServer
Function checkItemsTable ()
	
	for each row in ItemsTable do
		if ( not ValueIsFilled ( row.Item ) ) then
			meta = Metadata.Documents.SetupPrices.TabularSections.Items.Attributes;
			Output.ItemNotFilled ( new Structure ( "Column, Table", meta.Item.Presentation (), Items.GroupItems.Title ), "ItemsTable" );
			return false;
		endif; 
	enddo;
	return true;
	
EndFunction

&AtServer
Function checkPriceGroupsTable ()
	
	for each row in PriceGroupsTable do
		if ( not ValueIsFilled ( row.PriceGroup ) ) then
			meta = Metadata.Documents.SetupPrices.TabularSections.PriceGroups.Attributes;
			Output.ItemNotFilled ( new Structure ( "Column, Table", meta.PriceGroup.Presentation (), Items.GroupPriceGroups.Title ), "PriceGroupsTable" );
			return false;
		endif; 
	enddo;
	return true;
	
EndFunction

&AtServer
Function checkItemDoubles ()
	
	testColumns = "Item";
	usePackages = Options.Packages ();
	useChars = Options.Features ();
	if ( usePackages ) then
		testColumns = testColumns + ", Package";
	endif; 
	if ( useChars ) then
		testColumns = testColumns + ", Feature";
	endif; 
	doubleRows = CollectionsSrv.GetDuplicates ( ItemsTable, testColumns );
	if ( doubleRows <> undefined ) then
		for each row in doubleRows do
			doublesPresentation = "" + row.Item;
			if ( usePackages ) then
				doublesPresentation = doublesPresentation + ", " + row.Package;
			endif; 
			if ( useChars ) then
				doublesPresentation = doublesPresentation + ", " + row.Feature;
			endif; 
			Output.TableDoubleRows ( new Structure ( "Table, Values", Items.GroupItems.Title, doublesPresentation ), "ItemsTable" );
		enddo; 
		return false;
	endif;
	return true;
	
EndFunction

&AtServer
Function checkPriceGroupsDoubles ()
	
	doubleRows = CollectionsSrv.GetDuplicates ( PriceGroupsTable, "PriceGroup" );
	if ( doubleRows <> undefined ) then
		for each row in doubleRows do
			doublesPresentation = "" + row.PriceGroup;
			Output.TableDoubleRows ( new Structure ( "Table, Values", items.GroupPriceGroups.Title, doublesPresentation ), "PriceGroupsTable" );
		enddo; 
		return false;
	endif;
	return true;
	
EndFunction

&AtServer
Procedure uploadItemsPrices ()
	
	Object.Items.Clear ();
	Object.ItemsPrices.Clear ();
	for each row in ItemsPricesTable do
		if ( row.Use ) then
			rowItemsPrices = Object.ItemsPrices.Add ();
			rowItemsPrices.Prices = row.Prices;
		endif; 
	enddo; 
	for each row in ItemsTable do
		for each rowItemsPrices in Object.ItemsPrices do
			rowItems = Object.Items.Add ();
			rowItems.Item = row.Item;
			rowItems.Package = row.Package;
			rowItems.Feature = row.Feature;
			column = columnByRef ( rowItemsPrices.Prices );
			rowItems.PriceOrPercent = row [ column ];
			rowItems.Prices = rowItemsPrices.Prices;
		enddo; 
	enddo; 
	
EndProcedure

&AtServer
Procedure uploadPriceGroupsPrices ()
	
	Object.PriceGroups.Clear ();
	Object.PriceGroupsPrices.Clear ();
	for each row in PriceGroupsPricesTable do
		if ( row.Use ) then
			rowPriceGroupsPrices = Object.PriceGroupsPrices.Add ();
			rowPriceGroupsPrices.Prices = row.Prices;
		endif; 
	enddo; 
	for each row in PriceGroupsTable do
		for each rowPriceGroupsPrices in Object.PriceGroupsPrices do
			rowPriceGroups = Object.PriceGroups.Add ();
			column = columnByRef ( rowPriceGroupsPrices.Prices );
			rowPriceGroups.PriceGroup = row.PriceGroup;
			rowPriceGroups.Percent = row [ column ];
			rowPriceGroups.Prices = rowPriceGroupsPrices.Prices;
		enddo; 
	enddo; 
	
EndProcedure

&AtServer
Function checkSelectedPrices ()
	
	error = not checkSelectedPricesForTable ( "Organizations" );
	error = not checkSelectedPricesForTable ( "Warehouses" ) or error;
	return not error;
	
EndFunction 

&AtServer
Function checkSelectedPricesForTable ( CheckedTableName )
	
	checkedTable = Object [ CheckedTableName ].Unload ( , "Prices" );
	checkedTable.GroupBy ( "Prices" );
	meta = Metadata.Documents.SetupPrices.TabularSections;
	for each checkedRow in checkedTable do
		foundPricesRows = ItemsPricesTable.FindRows ( new Structure ( "Use, Prices", true, checkedRow.Prices ) );
		if ( foundPricesRows.Count () = 0 ) then
			Output.PricesNotRecognized ( new Structure ( "Prices, Table", checkedRow.Prices, meta [ CheckedTableName ].Presentation () ), CheckedTableName );
			return false;
		endif; 
	enddo; 
	return true;
	
EndFunction
	
&AtClient
Procedure OnOpen ( Cancel )
	
	initServiceFlags ();
	if ( Object.Ref.IsEmpty () ) then
		setItemsTableRowsCount ( ThisObject );
		setPriceGroupsTableRowsCount ( ThisObject );
	endif; 

EndProcedure

&AtClient
Procedure initServiceFlags ()
	
	RefillItemsTable = false;
	RefillPriceGroupsTable = false;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setItemsTableRowsCount ( Form )
	
	Form.ItemsTableRowsCount = Form.ItemsTable.Count ();
	
EndProcedure

&AtClientAtServerNoContext
Procedure setPriceGroupsTableRowsCount ( Form )

	Form.PriceGroupsTableRowsCount = Form.PriceGroupsTable.Count ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure ItemsCheckAll ( Command )
	
	RefillItemsTable = true;
	Forms.MarkRows ( ItemsPricesTable, true );
	
EndProcedure

&AtClient
Procedure ItemsUncheckAll ( Command )
	
	RefillItemsTable = true;
	Forms.MarkRows ( ItemsPricesTable, false );
	
EndProcedure

&AtClient
Procedure PriceGroupsCheckAll ( Command )
	
	RefillPriceGroupsTable = true;
	Forms.MarkRows ( PriceGroupsPricesTable, true );
	
EndProcedure

&AtClient
Procedure PriceGroupsUncheckAll ( Command )
	
	RefillPriceGroupsTable = true;
	Forms.MarkRows ( PriceGroupsPricesTable, false );
	
EndProcedure

&AtClient
Procedure ItemsMoveDown ( Command )
	
	RefillItemsTable = true;
	Forms.MoveRow ( ThisObject, "ItemsPricesTable", 1 );
	
EndProcedure

&AtClient
Procedure ItemsMoveUp ( Command )
	
	RefillItemsTable = true;
	Forms.MoveRow ( ThisObject, "ItemsPricesTable", -1 );
	
EndProcedure

&AtClient
Procedure PriceGroupsMoveUp ( Command )
	
	RefillPriceGroupsTable = true;
	Forms.MoveRow ( ThisObject, "PriceGroupsPricesTable", -1 );
	
EndProcedure

&AtClient
Procedure PriceGroupsMoveDown ( Command )
	
	RefillPriceGroupsTable = true;
	Forms.MoveRow ( ThisObject, "PriceGroupsPricesTable", 1 );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	fillPricesAndBuildTables ( Object.Ref );
	RefillItemsTable = false;
	RefillPriceGroupsTable = false;
	Items.Pages.CurrentPage = Items.GroupPrices;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	if ( RefillItemsTable and CurrentPage.Name = "GroupItems" ) then
		buildItemsAndPriceGroupsTable ( "ItemsTable" );
		RefillItemsTable = false;
	elsif ( RefillPriceGroupsTable and CurrentPage.Name = "GroupPriceGroups" ) then
		buildItemsAndPriceGroupsTable ( "PriceGroupsTable" );
		RefillPriceGroupsTable = false;
	endif; 
	
EndProcedure

// *****************************************
// *********** Table ItemsPricesTable

&AtClient
Procedure ItemsPricesTableSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = ( Item.CurrentItem.Name <> "Use" );
	openItemsCurrentValue ( Item );
	
EndProcedure

&AtClient
Procedure openItemsCurrentValue ( Item )
	
	if ( Item.CurrentItem.Name = "ItemsPricesPrices" ) then
		ShowValue ( , Item.CurrentData.Prices );
	elsif ( Item.CurrentItem.Name = "ItemsPricesBasePrices" ) then
		ShowValue ( , Item.CurrentData.BasePrices );
	endif; 
	
EndProcedure

&AtClient
Procedure ItemsPricesTableBeforeRowChange ( Item, Cancel )
	
	RefillItemsTable = true;
	
EndProcedure

// *****************************************
// *********** Table PriceGroupsTablePrices

&AtClient
Procedure PriceGroupsPricesTableSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openPriceGroupsPricesCurrentValue ( Item );
	
EndProcedure

&AtClient
Procedure openPriceGroupsPricesCurrentValue ( Item )
	
	if ( Item.CurrentItem.Name = "PriceGroupsPricesTablePrices" ) then
		ShowValue ( , Item.CurrentData.Prices );
	elsif ( Item.CurrentItem.Name = "PriceGroupsPricesTableBasePrices" ) then
		ShowValue ( , Item.CurrentData.BasePrices );
	endif; 
	
EndProcedure

&AtClient
Procedure PriceGroupsPricesTableBeforeRowChange ( Item, Cancel )
	
	RefillPriceGroupsTable = true;
	
EndProcedure

// *****************************************
// *********** Table ItemsTable

&AtClient
Procedure ItemsTableOnEditEnd ( Item, NewRow, CancelEdit )
	
	setPriceGroupsTableRowsCount ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsTableAfterDeleteRow ( Item )
	
	setItemsTableRowsCount ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsTableItemOnChange ( Item )
	
	setPackageAndCalcPrice ();
	
EndProcedure

&AtClient
Procedure setPackageAndCalcPrice ()
	
	rowFields = getItemsTableRowFields ();
	getPackageAndPrices ( rowFields, getPricingObjectFields ( Object ), PricesByItems );
	setItemsTableRowFields ( rowFields );
	
EndProcedure

&AtClientAtServerNoContext
Function getPricingObjectFields ( Object )
	
	return Collections.GetFields ( Object, "Date" );
	
EndFunction 

&AtClient
Function getItemsTableRowFields ()
	
	currentData = Items.ItemsTable.CurrentData;
	rowFields = new Structure ();
	rowFields.Insert ( "Item", currentData.Item );
	rowFields.Insert ( "Package", currentData.Package );
	rowFields.Insert ( "Feature", currentData.Feature );
	rowFields.Insert ( "Date", Object.Date );
	for each priceItem in PricesByItems do
		rowFields.Insert ( priceItem.Key );
	enddo;
	return rowFields;
	
EndFunction 

&AtServerNoContext
Procedure getPackageAndPrices ( RowFields, val ObjectFields, val PricesByItems )
	
	getPackage ( rowFields );
	getItemsTableRowPrice ( rowFields, ObjectFields, PricesByItems );
	
EndProcedure 

&AtServerNoContext
Procedure getPackage ( RowFields )
	
	if ( RowFields.Package.IsEmpty () ) then
		RowFields.Package = DF.Pick ( RowFields.Item, "Package" );
	endif; 
	
EndProcedure 

&AtServerNoContext
Procedure getItemsTableRowPrice ( RowFields, ObjectFields, PricesByItems )
	
	p = Goods.PriceParams ();
	p.Date = ObjectFields.Date;
	p.Item = RowFields.Item;
	p.Package = RowFields.Package;
	p.Feature = RowFields.Feature;
	cache = new Map ();
	for each priceItem in PricesByItems do
		p.Prices = priceItem.Value;
		RowFields [ priceItem.Key ] = Goods.GetPrice ( p, cache );
	enddo; 
	
EndProcedure 

&AtClient
Procedure setItemsTableRowFields ( RowFields )
	
	currentData = Items.ItemsTable.CurrentData;
	FillPropertyValues ( currentData, RowFields );
	
EndProcedure 

&AtClient
Procedure ItemsTablePackageOnChange ( Item )
	
	setItemsTableRowPrice ();
	
EndProcedure

&AtClient
Procedure setItemsTableRowPrice ()
	
	rowFields = getItemsTableRowFields ();
	getItemsTableRowPrice ( rowFields, getPricingObjectFields ( Object ), PricesByItems );
	setItemsTableRowFields ( rowFields );
	
EndProcedure

&AtClient
Procedure ItemsTableFeatureOnChange ( Item )
	
	setItemsTableRowPrice ();
	
EndProcedure

// *****************************************
// *********** Table PriceGroupsTable

&AtClient
Procedure PriceGroupsTableOnEditEnd ( Item, NewRow, CancelEdit )
	
	setPriceGroupsTableRowsCount ( ThisObject );
	
EndProcedure

&AtClient
Procedure PriceGroupsTableAfterDeleteRow ( Item )
	
	setPriceGroupsTableRowsCount ( ThisObject );
	
EndProcedure

&AtClient
Procedure PriceGroupsTablePriceGroupOnChange ( Item )
	
	rowFields = getPriceGroupsTableRowFields ();
	getPriceGroupPrices ( rowFields, PricesByGroups );
	setPriceGroupsTableRowFields ( rowFields );
	
EndProcedure

&AtClient
Function getPriceGroupsTableRowFields ()
	
	currentData = Items.PriceGroupsTable.CurrentData;
	rowFields = new Structure ();
	rowFields.Insert ( "PriceGroup", currentData.PriceGroup );
	rowFields.Insert ( "Date", Object.Date );
	for each priceItem in PricesByGroups do
		rowFields.Insert ( priceItem.Key );
	enddo;
	return rowFields;
	
EndFunction 

&AtServerNoContext
Procedure getPriceGroupPrices ( RowFields, val PricesByGroups )
	
	for each priceItem in PricesByGroups do
		priceStruct = new Structure ( "Prices, PriceGroup, Organization, Warehouse", priceItem.Value, RowFields.PriceGroup );
		RowFields [ priceItem.Key ] = InformationRegisters.PriceGroups.GetLast ( RowFields.Date, priceStruct ).Percent;
	enddo; 
	
EndProcedure 

&AtClient
Procedure setPriceGroupsTableRowFields ( RowFields )
	
	currentData = Items.PriceGroupsTable.CurrentData;
	FillPropertyValues ( currentData, RowFields );
	
EndProcedure 

// *****************************************
// *********** Table Organization

&AtClient
Procedure OrganizationPricesStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	openOrganizationPricesChoiceForm ( Item );
	
EndProcedure

&AtClient
Procedure openOrganizationPricesChoiceForm ( Item )
	
	filter = new Structure ( "Detail, Owner", new Array (), Object.Company );
	filter.Detail.Add ( PredefinedValue ( "Enum.PriceDetails.ItemAndOrganization" ) );
	filter.Detail.Add ( PredefinedValue ( "Enum.PriceDetails.ItemAndWarehouseAndOrganization" ) );
	OpenForm ( "Catalog.Prices.ChoiceForm", new Structure ( "Filter", filter ), Item );
	
EndProcedure

// *****************************************
// *********** Table Warehouses

&AtClient
Procedure WarehousesPricesStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	openWarehousePricesChoiceForm ( Item );
	
EndProcedure

&AtClient
Procedure openWarehousePricesChoiceForm ( Item )
	
	filter = new Structure ( "Detail, Owner", new Array (), Object.Company );
	filter.Detail.Add ( PredefinedValue ( "Enum.PriceDetails.ItemAndWarehouse" ) );
	filter.Detail.Add ( PredefinedValue ( "Enum.PriceDetails.ItemAndWarehouseAndOrganization" ) );
	OpenForm ( "Catalog.Prices.ChoiceForm", new Structure ( "Filter", filter ), Item );
	
EndProcedure
