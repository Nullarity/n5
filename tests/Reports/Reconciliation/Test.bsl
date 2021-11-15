
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BDBB1A4" );
env = getEnv ( id );
createEnv ( env );

p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Reconciliation Statement";
filters = new Array ();
item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = "01/01/2020";
item.ValueTo = "12/31/2020";
filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Name = "Organization";
item.Value = env.Customer;
filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Name = "Language";
item.Value = "Russian";
filters.Add ( item );
p.Filters = filters;
Call ( "Common.Report", p );

With ();
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "05/01/2020" );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Items", getItems ( ID ) );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "15.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "10.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "5.00", "15" ) );
	return list;

EndFunction

Function getItem ( Description, Price, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
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
		p.Service = true;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// *************************
	// Create Invoice
	// *************************

	p = Call ( "Documents.Invoice.Sale.Params" );
	p.Date = Env.Date;
	p.Action = "Post";
	p.Customer = Env.Customer;
	p.Warehouse = Env.Warehouse;
	items = p.Services;
	for each row in Env.Items do
		newRow = Call ( "Documents.Invoice.Sale.ServicesRow" );
		FillPropertyValues ( newRow, row );
		items.Add ( newRow );
	enddo;
	invoiceForm = Call ( "Documents.Invoice.Sale", p );
	
	// *************************
	// Create Payment
	// *************************

	Click ( "#CreatePayment", invoiceForm );
	form = With ( "Customer Payment (cr*" );
	Set ( "#Date", Env.Date );
	Set ( "#Amount", "200.00" );
	Set ( "#Account", "2422" );
	Click ( "#FormPost", form );
	
	// *************************
	// Create Invoice
	// *************************

	p = Call ( "Documents.Invoice.Sale.Params" );
	p.Date = Env.Date;
	p.Action = "Post";
	p.Customer = Env.Customer;
	p.Warehouse = Env.Warehouse;
	items = p.Services;
	for each row in Env.Items do
		newRow = Call ( "Documents.Invoice.Sale.ServicesRow" );
		FillPropertyValues ( newRow, row );
		items.Add ( newRow );
	enddo;
	Call ( "Documents.Invoice.Sale", p );
		
	RegisterEnvironment ( id );
	
EndProcedure
