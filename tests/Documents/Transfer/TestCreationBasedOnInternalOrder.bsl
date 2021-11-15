Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// Clear Warehouse
MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Users" );
list = With ();

p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = "admin";
Call ( "Common.Find", p );

With ( list );
Click ( "#FormChange" );

With ();

userWarehouse = Fetch ( "#Warehouse" );

Clear ( "#Warehouse" );
Click ( "#FormWriteAndClose" );

internalOrders = Call ( "Common.OpenList", Meta.Documents.InternalOrder );

Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );
Put ( "#StatusFilter", "Active" );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.ID;
Call ( "Common.Find", p );

Click ( "#FormDocumentTransferCreateBasedOn" );
transfer = With ( "Transfer *" );
Click ( "#FormPost" );

CheckErrors ();

Click ( "#FormReportRecordsShow" );

form = With ( "Records: Transfer *" );
Call ( "Common.CheckLogic", "#TabDoc" );

With ( transfer );
Click ( "#FormUndoPosting" );

// Set User Warehouse
MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Users" );
list = With ();

p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = "admin";
Call ( "Common.Find", p );

With ( list );
Click ( "#FormChange" );

With ();

Put ( "#Warehouse", userWarehouse );
Click ( "#FormWriteAndClose" );

// *************************
// Procedures
// *************************

Function getEnv ()
	
	id = Call ( "Common.ScenarioID", "286E2961" ) + "#";
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "WarehouseA", "_WarehouseA: " + id );
	env.Insert ( "WarehouseB", "_WarehouseB: " + id );
	env.Insert ( "Department", "_Department: " + id );
	env.Insert ( "Responsible", "_Responsible: " + id );
	env.Insert ( "User", "admin" );
	items = new Array ();
	items.Add ( newItem ( "_Item " + id, 10, 150 ) );
	items.Add ( newItem ( "_Item, pkg " + id, 15, 250, true ) );
	env.Insert ( "Items", items );
	return env;
	
EndFunction

Function newItem ( Item, Quantity, Price, CountPackages )
	
	p = new Structure ( "Item, Quantity, Price, CountPackages" );
	p.Item = Item;
	p.Quantity = Quantity;
	p.Price = Price;
	p.CountPackages = CountPackages;
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************
	// Create Department, Responsible
	// ***********************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );
	
	// ***********************
	// Create Warehouse
	// ***********************
	
	Call ( "Catalogs.Warehouses.Create", Env.WarehouseA );
	Call ( "Catalogs.Warehouses.Create", Env.WarehouseB );
	
	// ***********************
	// Create Items
	// ***********************
	
	for each item in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = item.Item;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// *****************************
	// Receive items
	// *****************************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = env.date - 86400;
	p.Warehouse = env.warehouseA;
	p.Account = "8111";
	
	goods = new Array ();
	for each rowItem in Env.Items do
		row = Call ( "Documents.ReceiveItems.Receive.Row" );
		row.Item = rowItem.Item;
		row.CountPackages = rowItem.CountPackages;
		row.Quantity = rowItem.Quantity;
		row.Price = "7";
		goods.Add ( row );
	enddo;
	p.Items = goods;
	Call ( "Documents.ReceiveItems.Receive", p );
	
	// ***********************************
	// Roles: Division head
	// ***********************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	Put ( "#User", Env.user );
	Pick ( "#Role", "Department Head" );
	Set ( "#Department", Env.department );
	CurrentSource.GotoNextItem ();
	Click ( "#Apply" );
	
	// ***********************************
	// Roles: Warehouse manager
	// ***********************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	Put ( "#User", Env.user );
	Pick ( "#Role", "Warehouse Manager" );
	Click ( "#Apply" );
	
	// *****************************
	// Internal Order
	// *****************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Document.InternalOrder" );
	
	form = With ( "Internal Order (create)" );
	Put ( "#Date", env.Date ); // It is important to be first
	Put ( "#Department", env.Department );
	Put ( "#Warehouse", env.WarehouseB );
	Put ( "#Responsible", env.Responsible );
	Put ( "#TaxCode", "Taxable Sales" );
	Put ( "#TaxGroup", "California" );
	Put ( "#Memo", id );
	
	table = Activate ( "#ItemsTable" );
	
	for each row in env.Items do
		Click ( "#ItemsTableAdd" );
		table.EndEditRow ();
		Put ( "#ItemsItem", row.Item, table );
		Put ( "#ItemsQuantity", row.Quantity, table );
		Put ( "#ItemsPrice", row.Price, table );
		Next ();
//		table.EndEditRow ();
		table.ChangeRow ();
		Set ( "#ItemsReservation", "Warehouse", table );
		Put ( "#ItemsStock", env.WarehouseA, table );
		
	enddo;
	
	Click ( "#FormSendForApproval" );
	With ( DialogsTitle );
	Click ( "Yes" );
	// ***********************************
	// Open list and approve IO
	// ***********************************
	
	internalOrders = Call ( "Common.OpenList", Meta.Documents.InternalOrder );
	
	Clear ( "#StatusFilter" );
	Clear ( "#ItemFilter" );
	Clear ( "#WarehouseFilter" );
	Clear ( "#DepartmentFilter" );
	Put ( "#StatusFilter", "Active" );
	
	p = Call ( "Common.Find.Params" );
	p.Where = "Memo";
	p.What = id;
	Call ( "Common.Find", p );
	
	Click ( "#FormChange" );
	formOrder = With ( "Internal Order #*" );
	Click ( "#FormCompleteApproval" );
	
	With ( DialogsTitle );
	Click ( "Yes" );
	
	With ( internalOrders );
	Click ( "#FormChange" );
	Run ( "TestRecordsInternalOrder" );
	
	RegisterEnvironment ( id );
	
EndProcedure

