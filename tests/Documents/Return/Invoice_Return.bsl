// Check filling Return by Invoice and check records:
// - Create VendorInvoice
// - Create Invoice
// - Generate Return
// - Post & CheckTemplate

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BDCD60E" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create VendorInvoice
// *************************

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Vendor = env.Vendor;
p.Warehouse = env.Warehouse;
p.ID = id;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	FillPropertyValues ( newRow, row );
	items.Add ( newRow );
enddo;
Call ( "Documents.VendorInvoice.Buy", p );

// *************************
// Create Invoice
// *************************

p = Call ( "Documents.Invoice.Sale.Params" );
p.Action = "Post";
p.Customer = env.Customer;
p.Warehouse = env.Warehouse;
items = p.Items;
for each row in env.Items do
	newRow = Call ( "Documents.Invoice.Sale.ItemsRow" );
	FillPropertyValues ( newRow, row );
	newRow.Price = row.RetailPrice;
	items.Add ( newRow );
enddo;
invoiceForm = Call ( "Documents.Invoice.Sale", p );

// *************************
// Generate Return
// *************************

Click ( "#FormDocumentReturnCreateBasedOn", invoiceForm );

// *************************
// Post & CheckTemplate
// *************************

With ( "Return from *" );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Return *" );
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "15.00", "20.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "10.00", "15.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "5.00", "7.50", "15" ) );
	return list;

EndFunction

Function getItem ( Description, Price, RetailPrice, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "RetailPrice", RetailPrice );
	p.Insert ( "Quantity", Quantity );
	return p;	

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	for each row in env.Items do
		p.Description = row.Item;
		Call ( "Catalogs.Items.Create", p );
	enddo;
		
	RegisterEnvironment ( id );
	
EndProcedure