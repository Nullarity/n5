&AtServer
var Env;
&AtServer
var ProductionOrderExists;
&AtServer
var Base;
&AtServer
var BaseType;
&AtServer
var Copy;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtClient
var ExpensesRow;

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
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
			fillByWorkshop ();
		else
			BaseType = TypeOf ( Base );
			if ( BaseType = Type ( "DocumentRef.ProductionOrder" ) ) then
				fillByProductionOrder ();
			elsif ( BaseType = Type ( "DocumentRef.InternalOrder" )
				or BaseType = Type ( "DocumentRef.SalesOrder" ) ) then
				fillByOrder ();
			endif; 
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif;
	setLinks ();
	setAccuracy ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services" );
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
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Write show empty ( Object.Ref );
	|Expenses enable filled ( Object.Ref );
	|ItemsApplyPurchaseOrders ItemsTableApplyInternalOrders ItemsTableApplySalesOrders ServicesApplyPurchaseOrders ServicesApplyInternalOrders ServicesApplySalesOrders show empty ( Object.ProductionOrder );
	|Company Workshop Department lock filled ( Object.ProductionOrder );
	|Links show ShowLinks
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company, Warehouse, Workshop, Stock" );
	if ( Object.Workshop.IsEmpty () ) then
		Object.Workshop = settings.Workshop;
	else
		Object.Company = DF.Pick ( Object.Department, "Owner" );
	endif;
	if ( Object.Warehouse.IsEmpty () ) then
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	if ( Object.Company.IsEmpty () ) then
		Object.Company = settings.Company;
	endif;
	Object.Stock = Settings.Stock;
	
EndProcedure 

&AtServer
Procedure fillByWorkshop ()
	
	apply = Parameters.FillingValues.Property ( "Workshop" )
	and not Copy
	and not Object.Workshop.IsEmpty ();
	if ( apply ) then
		applyWorkshop ();
	endif;

EndProcedure 

&AtServer
Procedure applyWorkshop ()
	
	workshop = Object.Workshop;
	Object.Department = DF.Pick ( workshop, "Department" );
	applyDepartment ();
	
EndProcedure

&AtServer
Procedure applyDepartment ()
	
	reloadTables ();
	
EndProcedure

&AtServer
Procedure reloadTables ()
	
	table = FillerSrv.GetData ( fillingParams ( "ProductionOrderItems", Object.ProductionOrder ) );
	if ( table.Count () > 0 ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
		loadProductionOrders ( table );
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ( val Report, val BaseDocument )
	
	p = Filler.GetParams ();
	p.ProposeClearing = Object.ProductionOrder.IsEmpty ();
	p.Report = Report;
	if ( Report = Metadata.Reports.SalesOrderItems.Name ) then
		p.Variant = "#FillProductionOrder";
	endif; 
	p.Filters = getFilters ( Report, BaseDocument );
	return p;
	
EndFunction

&AtServer
Function getFilters ( Report, BaseDocument )
	
	meta = Metadata.Reports;
	workshop = Object.Workshop;
	warehouse = Object.Warehouse;
	department = Object.Department;
	filters = new Array ();
	if ( Report = meta.ProductionOrderItems.Name ) then
		if ( BaseDocument.IsEmpty () ) then
			if ( not workshop.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "ProductionOrder.Workshop", workshop ) );
			endif; 
			if ( not department.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "ProductionOrder.Department", department ) );
			endif; 
			if ( not warehouse.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "ProductionOrder.Warehouse", warehouse ) );
			endif; 
		else
			filters.Add ( DC.CreateFilter ( "ProductionOrder", BaseDocument ) );
		endif; 
	else
		if ( BaseDocument = undefined ) then
			if ( not department.IsEmpty () ) then
				filters.Add ( DC.CreateParameter ( "Department", department ) );
			endif;
			if ( not warehouse.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "Warehouse", warehouse ) );
			endif; 
		else
			if ( Report = meta.InternalOrders.Name ) then
				filters.Add ( DC.CreateFilter ( "InternalOrder", BaseDocument ) );
			else
				filters.Add ( DC.CreateFilter ( "SalesOrder", BaseDocument ) );
			endif;
		endif;
	endif; 
	item = DC.CreateParameter ( "ReportDate" );
	item.Value = Catalogs.Calendar.GetDate ( Periods.GetBalanceDate ( Object ) );
	item.Use = not item.Value.IsEmpty ();
	filters.Add ( item );
	return filters;
	
EndFunction

#region Filling

&AtServer
Procedure fillByProductionOrder ()
	
	setEnv ();
	sqlProductionOrder ();
	SQL.Perform ( Env );
	headerByProductionOrder ();
	table = FillerSrv.GetData ( fillingParams ( "ProductionOrderItems", Object.ProductionOrder ) );
	loadProductionOrders ( table );
	
EndProcedure 

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlProductionOrder ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Workshop as Workshop, Documents.Department as Department,
	|	Documents.Warehouse as Warehouse
	|from Document.ProductionOrder as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByProductionOrder ()

	FillPropertyValues ( Object, Env.Fields );
	Object.ProductionOrder = Base;

EndProcedure 

&AtServer
Procedure fillByOrder ()
	
	setEnv ();
	sqlOrder ();
	SQL.Perform ( Env );
	headerByOrder ();
	if ( BaseType = Type ( "DocumentRef.InternalOrder" ) ) then
		table = FillerSrv.GetData ( fillingParams ( "InternalOrders", Base ) );
		loadInternalOrders ( table );
	else
		table = FillerSrv.GetData ( fillingParams ( "SalesOrderItems", Base ) );
		loadSalesOrders ( table );
	endif; 
	
EndProcedure 

&AtServer
Procedure sqlOrder ()
	
	if ( BaseType = Type ( "DocumentRef.InternalOrder" ) ) then
		name = "InternalOrder";
	else
		name = "SalesOrder";
	endif; 
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Warehouse as Warehouse
	|from Document." + name + " as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByOrder ()
	
	FillPropertyValues ( Object, Env.Fields );
	
EndProcedure 

&AtServer
Procedure loadInternalOrders ( Table )
	
	company = Object.Company;
	warehouses = Options.WarehousesInTable ( company );
	warehouse = Object.Warehouse;
	services = Object.Services;
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService = null ) then
			continue;
		endif;
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			docRow.Description = DF.Pick ( row.Item, "FullDescription" );
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			Computations.Packages ( docRow );
			if ( warehouses
				and docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account" );
			docRow.Account = accounts.Account;
		endif; 
		docRow.BOM = row.Item.BOM;
		docRow.DocumentOrder = row.InternalOrder;
		docRow.DocumentOrderRowKey = row.RowKey;
	enddo; 
	
EndProcedure 

&AtServer
Procedure loadSalesOrders ( Table )
	
	company = Object.Company;
	warehouses = not Options.WarehousesInTable ( company );
	warehouse = Object.Warehouse;
	services = Object.Services;
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService = null ) then
			continue;
		endif;
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			if ( warehouses
				or docRow.Warehouse = Object.Warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account" );
			docRow.Account = accounts.Account;
		endif; 
		if ( row.ItemService ) then
			docRow.Description = DF.Pick ( row.Item, "FullDescription" );
		endif; 
		docRow.BOM = row.Item.BOM;
		docRow.DocumentOrder = row.SalesOrder;
		docRow.DocumentOrderRowKey = row.RowKey;
	enddo; 
	
EndProcedure 

&AtServer
Procedure loadProductionOrders ( Table )
	
	company = Object.Company;
	warehouses = Options.WarehousesInTable ( company );
	orders = Options.ProductionOrdersInTable ( company );
	warehouse = Object.Warehouse;
	productionOrder = Object.ProductionOrder;
	services = Object.Services;
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			docRow.Description = DF.Pick ( row.Item, "FullDescription" );
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			if ( warehouses
				and docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account" );
			docRow.Account = accounts.Account;
		endif; 
		if ( orders
			and docRow.ProductionOrder = productionOrder ) then
			docRow.ProductionOrder = undefined;
		endif; 
		docRow.BOM = docRow.Item.BOM;
	enddo; 
	
EndProcedure 

#endregion

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "ProductionOrder", Object.ProductionOrder );
		SQL.Perform ( env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	ProductionOrderExists = not Object.ProductionOrder.IsEmpty ();
	selection = Env.Selection;
	if ( ProductionOrderExists ) then
		s = "
		|// #ProductionOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.ProductionOrder as Documents
		|where Documents.Ref = &ProductionOrder
		|";
		selection.Add ( s );
	endif;
	s = "
	|// #Services
	|select distinct Services.Ref as Document, Services.Ref.Date as Date, Services.Ref.Number as Number
	|from Document.Production.Services as Services
	|where Services.IntoDocument = &Ref
	|and not Services.Ref.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( ProductionOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.ProductionOrders, meta.ProductionOrder ) );
	endif;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Services, meta.Production ) );
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
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	
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
	Forms.DeleteLastRow ( Object.Expenses, "Item" );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		row.BOM = item.BOM;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		warehouse = Object.Warehouse;
		accounts = AccountsMap.Item ( item, Object.Company, warehouse, "Account" );
		row.Account = accounts.Account;
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
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	tableItems = Object.Items;
	for each selectedRow in Params.Items do
		row = tableItems.Add ();
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

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageProductionIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	applyDate ();
	
EndProcedure

&AtServer
Procedure applyDate ()
	
	reloadTables ();
	updateChangesPermission ()

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure WorkshopOnChange ( Item )
	
	applyWorkshop ();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange ( Item )
	
	applyDepartment ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ApplyProductionOrders ( Command )
	
	Filler.Open ( fillingParams ( "ProductionOrderItems", Object.ProductionOrder ), ThisObject );
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result, Params.Report ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result, val Report )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	if ( Result.ClearTable ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
	endif; 
	meta = Metadata.Reports;
	if ( Report = meta.ProductionOrderItems.Name ) then
		loadProductionOrders ( table );
	elsif ( Report = meta.InternalOrders.Name ) then
		loadInternalOrders ( table );
	elsif ( Report = meta.SalesOrderItems.Name ) then
		loadSalesOrders ( table );
	endif; 
	
EndFunction

&AtClient
Procedure ApplySalesOrders ( Command )
	
	Filler.Open ( fillingParams ( "SalesOrderItems", undefined ), ThisObject );
	
EndProcedure

&AtClient
Procedure ApplyInternalOrders ( Command )
	
	Filler.Open ( fillingParams ( "InternalOrders", undefined ), ThisObject );
	
EndProcedure

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( productionOrderColumn ( Item )
		and not ItemsRow.ProductionOrder.IsEmpty () ) then
		StandardProcessing = false;
		ShowValue ( , ItemsRow.ProductionOrder );
	endif; 
	
EndProcedure

&AtClient
Function productionOrderColumn ( Item )
	
	return Find ( Item.CurrentItem.Name, "ProductionOrder" ) > 0;
	
EndFunction 

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Item", ItemsRow.Item );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.BOM = data.BOM;
	ItemsRow.Account = data.Account;
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, BOM" );
	accounts = AccountsMap.Item ( item, Params.Company, Params.Warehouse, "Account" );
	data.Insert ( "Account", accounts.Account );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ( ItemsRow );
	
EndProcedure

&AtClient
Procedure applyPackage ( TableRow )
	
	ItemsRow.Capacity = DF.Pick ( TableRow.Package, "Capacity", 1 );
	Computations.Units ( TableRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( productionOrderColumn ( Item )
		and not ServicesRow.ProductionOrder.IsEmpty () ) then
		StandardProcessing = false;
		ShowValue ( , ServicesRow.ProductionOrder );
	endif; 
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Item", ServicesRow.Item );
	data = getServiceData ( p );
	ServicesRow.Description = data.FullDescription;
	ServicesRow.Account = data.Account;
	ServicesRow.Expense = data.Expense;
	ServicesRow.Department = data.Department;
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription" );
	warehouse = Params.Warehouse;
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account, Department, Expense" );
	data.Insert ( "Account", accounts.Account );
	data.Insert ( "Expense", accounts.Expense );
	data.Insert ( "Department", accounts.Department );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesDistributionOnChange ( Item )
	
	resetDistribution ();
	
EndProcedure

&AtClient
Procedure resetDistribution ()
	
	if ( ServicesRow.Distribution.IsEmpty () ) then
		ServicesRow.IntoDocument = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure ServicesIntoDocumentOnChange ( Item )
	
	applyDocument ();
	
EndProcedure

&AtClient
Procedure applyDocument ()
	
	if ( ServicesRow.IntoDocument.IsEmpty () ) then
		ServicesRow.Distribution = undefined;
	else
		ServicesRow.Distribution = PredefinedValue ( "Enum.ProductionDistribution.Quantity" );
	endif;
	
EndProcedure

// *****************************************
// *********** Table Expenses

&AtClient
Procedure CalculateExpenses ( Command )
	
	applyExpenses ();
	
EndProcedure

&AtServer
Procedure applyExpenses ()
	
	Write ();
	table = Object.Expenses;
	table.Clear ();
	company = Object.Company;
	stock = Object.Stock;
	for each row in getExpenses () do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( row.Item, company, stock, "Account, ExpenseAccount" );
		newRow.Account = accounts.Account;
		newRow.ExpenseAccount = accounts.ExpenseAccount;
	enddo;
	
EndProcedure

&AtServer
Function getExpenses ()
	
	s = "
	|select BOMs.Ref.Item as Product, BOMs.Item as Item, BOMs.Capacity as Capacity, BOMs.Feature as Feature,
	|	BOMs.Package as Package, BOMs.Ref.Expense as Expense,
	|	BOMs.Quantity * Products.Quantity / BOMs.Ref.Quantity as Quantity,
	|	BOMs.QuantityPkg * Products.QuantityPkg / BOMs.Ref.QuantityPkg as QuantityPkg
	|from Catalog.BOM.Items as BOMs
	|	//
	|	// Join Products
	|	//
	|	join Document.Production.Items as Products
	|	on Products.Ref = &Ref
	|	and Products.BOM = BOMs.Ref
	|order by Products.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	return q.Execute ().Unload ();
	
EndFunction

&AtClient
Procedure ExpensesOnActivateRow ( Item )
	
	ExpensesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ExpensesItemOnChange ( Item )
	
	applyExpense ();
	
EndProcedure

&AtClient
Procedure applyExpense ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Stock );
	p.Insert ( "Item", ExpensesRow.Item );
	data = getExpenseData ( p );
	ExpensesRow.Package = data.Package;
	ExpensesRow.Capacity = data.Capacity;
	ExpensesRow.Account = data.Account;
	ExpensesRow.ExpenseAccount = data.ExpenseAccount;
	Computations.Units ( ExpensesRow );
	
EndProcedure 

&AtServerNoContext
Function getExpenseData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity" );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	accounts = AccountsMap.Item ( item, Params.Company, Params.Warehouse, "Account, ExpenseAccount" );
	data.Insert ( "Account", accounts.Account );
	data.Insert ( "ExpenseAccount", accounts.ExpenseAccount );
	return data;
	
EndFunction 

&AtClient
Procedure ExpensesQuantityPkgOnChange ( Item )
	
	Computations.Units ( ExpensesRow );
	
EndProcedure

&AtClient
Procedure ExpensesPackageOnChange ( Item )
	
	applyPackage ( ExpensesRow );
	
EndProcedure

&AtClient
Procedure ExpensesQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure
