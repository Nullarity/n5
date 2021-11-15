Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// ***********************************
// Create WriteOff
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.WriteOff" );
With ( "Write Offs" );
Click ( "#FormCreate" );
formWriteOff = With ( "Write Off (create)" );
Put ( "#Warehouse", env.WarehouseB );
Put ( "#ExpenseAccount", "8111" );

// *************************
// Items Selection
// *************************

Click ( "#ItemsSelectItems" );

selectionForm = With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;	
//Set ( "#Filter", "Reserve Only" );
Pick ( "#Filter", "Reserve Only" );


table = Get ( "#ItemsList" );

for i = 1 to 2 do
	row = Env.Items [ i - 1 ];
	GoToRow ( table, "Item", row.Item );
	table.Choose ();
	if ( i = 2 ) then // count packages
		With ( selectionForm );
		tablePackages = Get ( "#PackagesList" );
		tablePackages.Choose ();
	endif;
	With ( "Details" );
	Put ( "#Quantity", row.Quantity );
	Click ( "#ChangeReservationChangeReserveQuantity" );
	Click ( "#FormOK" );
enddo;
With ( selectionForm );
Click ( "#FormOK" );
With ( formWriteOff );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
form = With ( "Records: Write Off *" );
Call ( "Common.CheckLogic", "#TabDoc" );
With ( formWriteOff );
Click ( "#FormUndoPosting" );

// ***********************************
//  Procedures
// ***********************************

Function getEnv ()
	
	env = new Structure ();
	id = "#" + Call ( "Common.ScenarioID", "286CFDFB" );
	env.Insert ( "ID", id );
	date = CurrentDate ();
	env.Insert ( "Date", date );
	receiveDate = date - 86400;
	env.Insert ( "ReceiveDate", receiveDate );
	env.Insert ( "Customer", "_Customer: " + id );
	env.Insert ( "WarehouseA", "_WarehouseA " + id );
	env.Insert ( "WarehouseB", "_WarehouseB " + id );
	env.Insert ( "Department", "_Sales with Shipmets " + id );
	env.Insert ( "User", "admin" );
	env.Insert ( "Company", "ABC Distributions" );
	env.Insert ( "PaymentOptions", "nodiscount#" );
	env.Insert ( "Terms", "100% prepay, 0-1-5#" );
	env.Insert ( "Items", getItems ( id ) );
	env.Insert ( "Vendor", "_Vendor: " + id );
	return env;
	
EndFunction

Function getItems ( ID )
	
	items = new Array ();
	item = new Structure ();
	item.Insert ( "Item", "_Item1: " + ID );
	item.Insert ( "Quantity", 10 );
	item.Insert ( "Price", 100 );
	item.Insert ( "CountPackages", false );
	items.Add ( item );
	item = new Structure ();
	item.Insert ( "Item", "_Item2, countPkg: " + ID );
	item.Insert ( "Price", 200 );
	item.Insert ( "Quantity", 20 );
	item.Insert ( "CountPackages", true );
	items.Add ( item );
	return items;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create Department
	// ***********************************
	
	params = Call ( "Catalogs.Departments.Create.Params" );
	params.Description = Env.department;
	params.Shipments = false;
	params.Company = Env.company;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Departments;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
	// ***********************************
	// Create PaymentOption
	// ***********************************
	
	params = Call ( "Catalogs.PaymentOptions.Create.Params" );
	params.Description = Env.paymentOptions;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.PaymentOptions;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
	// ***********************************
	// Create Terms
	// ***********************************
	
	params = Call ( "Catalogs.Terms.Create.Params" );
	params.Description = Env.terms;
	payments = params.Payments;
	row = Call ( "Catalogs.Terms.Create.Row" );
	row.Option = Env.paymentOptions;
	row.Variant = "On delivery";
	row.Percent = "100";
	payments.Add ( row );
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Terms;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
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
	
	// ***********************************
	// Create Items
	// ***********************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	for each row in env.Items do
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
		Call ( "Catalogs.Items.Create", p );	
	enddo;
	
	// ***********************************
	// Create Customer
	// ***********************************
	customerData = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	customerData.Description = env.Customer;
	customerData.Terms = env.Terms;
	Call ( "Catalogs.Organizations.CreateCustomer", customerData );
	
	// ***********************************
	// Create Vendor
	// ***********************************

	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// ***********************************
	// Create Warehouses
	// ***********************************
	
	Call ( "Catalogs.Warehouses.Create", env.WarehouseA );
	Call ( "Catalogs.Warehouses.Create", env.WarehouseB );
	
	// ***********************************
	// Create Sales Order
	// ***********************************
	
	OpenMenu ( "Sales / Sales Order" );
	form = With ( "Sales Order (*" );
	//Click ( "FormCreate" );
	Put ( "#Customer", env.Customer );
	Put ( "#Warehouse", env.WarehouseA );
	Put ( "#Department", env.Department );
	Put ( "#Memo", id );
	
	table = Activate ( "#ItemsTable" );
	
	for each row in env.Items do
		Click ( "#ItemsTableAdd" );
		
		Put ( "#ItemsItem", row.Item, table );
		Put ( "#ItemsQuantity", row.Quantity, table );
		Put ( "#ItemsPrice", row.Price, table );
		table.EndEditRow ();
		table.ChangeRow ();
		Put ( "#ItemsReservation", "Next Receipts", table );
	enddo;
	With ( form );
	Click ( "#FormSendForApproval" );
	
	With ( DialogsTitle );
	Click ( "Yes" );
	
	// ***********************************
	// Open list and approve SO
	// ***********************************
	
	salesOrders = Call ( "Common.OpenList", Meta.Documents.SalesOrder );
	
	Clear ( "#CustomerFilter" );
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
	formOrder = With ( "Sales Order #*" );
	Click ( "#FormCompleteApproval" );
	
	With ( DialogsTitle );
	Click ( "Yes" );
	
	With ( salesOrders );
	Click ( "#FormChange" );
	
	formOrder = With ( "Sales Order #*" );
	With ( formOrder );
	
	// ***********************************
	//  Purchase Order
	// ***********************************
	
	Click ( "#FormPurchaseOrder" );
	
	formPO = With ( "Purchase Order (create)" );
	Put ( "#Vendor", env.Vendor );
	Put ( "#Warehouse", env.WarehouseA );
	Put ( "#Department", env.Department );
	Click ( "#FormPost" );
	With ( formPO );
	Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
	
	// ***********************************
	//  Vendor Invoice
	// ***********************************
	
	formVI = With ( "Vendor Invoice (create)" );
	Put ( "#Warehouse", env.WarehouseB ); 
	Click ( "#FormPost" );
	
	RegisterEnvironment ( id );
	CloseAll ();
	
EndProcedure

