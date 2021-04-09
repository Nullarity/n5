// Purchase forms an register range
// Sell services
// Create an Invoice Record and print it
// Check automatic Write Off

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AAD0F" );
env = getEnv ( id );
createEnv ( env );

// Sell services
p = Call ( "Documents.Invoice.Sale.Params" );
p.Warehouse = env.warehouse;
p.Department = env.Department;
p.Customer = env.Customer;

invoiceServices = new Array ();
row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "Service " + id;
row.Quantity = "1";
row.Price = "1500";
invoiceServices.Add ( row );

p.Services = invoiceServices;
p.Action = "Post";
Call ( "Documents.Invoice.Sale", p );

// Create an Invoice Record and print it
With();
Click("#NewInvoiceRecord");
With();
Choose ( "#Range" );
With ();
GotoRow("#List", "Range", "Invoice Records " + env.FormPrefix + " 1 - " + env.Quantity);
Click ( "#FormChoose" );
With();
Click ("#FormPrint");

// Close form and click Write Off hyperlink
Close("* Print");
With();
Get("#Links").ClickFormattedStringHyperlink ( 1 );
With();
Click("#FormReportRecordsShow");
With();
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "FormPrefix", Right(ID, 5) );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Price", 1 );
	p.Insert ( "Quantity", 300 );
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
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

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
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	p.Form = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *********************
	// Create Vendor Invoice
	// *********************
	
	Commando("e1cib/command/Document.VendorInvoice.Create");
	table = Get("#ItemsTable");
	Set("#Vendor", env.Vendor);
	Set("#Warehouse", env.Warehouse);
	Click("#ItemsTableAdd");
	Set("#ItemsItem", env.Item);
	Set("#ItemsQuantity", env.Quantity);
	Set("#ItemsPrice", env.Price);
	table.EndEditRow ();
	Activate("#ItemsRange").Create();
	With();
	Set("#Prefix", env.FormPrefix);
	Set("#Start", 1);
	Set("#Finish", env.Quantity);
	Set("#Length", 3);
	Set("#ExpenseAccount", "7118");
	Click("#WriteAndClose");
	With();
	Click("#FormPostAndClose");
	
	RegisterEnvironment ( id );
	
EndProcedure
