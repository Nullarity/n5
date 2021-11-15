Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "271BAF29" );
env = getEnv (id);
createEnv ( env );

// *************************
// Create Payments
// *************************

Commando ( "e1cib/list/Document.Invoice" );
With ( "Invoices" );
Clear ( "#CustomerFilter, #WarehouseFilter" );
GotoRow ( "#List", "Memo", Env.ID );
Click ( "#FormDocumentPaymentCreateBasedOn" );

With ( "Customer Payment (cr*" );

invoice = Fetch ( "Detailing Document", Get ( "#Payments" ) );
if ( invoice = "" ) then
	Stop ( "Invoice should be in the Payments table as Detailed Document" );
endif;

invoices = Call ( "Table.Count", Get ( "#Payments" ) );
if ( invoices > 1 ) then
	Stop ( "Payments table should have only one invoice" );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "SODate", date - 86400 );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists(id) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.Terms = "Main";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create SO
	// *************************
	
	p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
	p.Date = Env.SODate;
	p.Customer = Env.Customer;
	p.Memo = Env.ID;
	row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
	row.Item = "_Service: " + id;
	row.Quantity = 1;
	row.Price = 100;
	row.Performer = "None";
	p.Services.Add ( row );
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p );
	
	// *************************
	// Create & post Invoice #1
	// *************************
	
	Commando ( "e1cib/list/Document.SalesOrder" );
	With ( "Sales Orders" );
	Clear ( "#CustomerFilter, #StatusFilter, #ItemFilter, #WarehouseFilter, #DepartmentFilter" );
	GotoRow ( "#List", "Memo", id );
	Click ( "#FormDocumentInvoiceCreateBasedOn" );
	With ( "Invoice (cr*" );
	table = Get ( "#Services" );
	Set ( "#ServicesQuantity", 0, table );
	Set ( "#ServicesPrice", 50, table );
	Click ( "#FormPost" );
	Close ();
	
	// *************************
	// Create & post Invoice #2
	// *************************
	
	With ( "Sales Orders" );
	Click ( "#FormDocumentInvoiceCreateBasedOn" );
	With ( "Invoice (cr*" );
	table = Get ( "#Services" );
	Set ( "#ServicesQuantity", 0, table );
	Set ( "#ServicesPrice", 50, table );
	Set ( "#Memo", id );
	Click ( "#FormPost" );
	Close ();
	
	RegisterEnvironment(id);
	
EndProcedure
