Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
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

// *************************
// Procedures
// *************************

Function getEnv ()
	
	date = CurrentDate ();
	id = Call ( "Common.ScenarioID", "27113F36" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Customer", "_Customer: " + id );
	p.Insert ( "SODate", date - 86400 );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	p.Terms = "Main";
	p.Memo = Env.ID;
	row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
	row.Item = "_Service: " + id;
	row.Quantity = 1;
	row.Price = 100;
	row.Performer = "None";
	p.Services.Add ( row );
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p );
	
	// *************************
	// Create & post Invoice
	// *************************
	
	Commando ( "e1cib/list/Document.SalesOrder" );
	With ( "Sales Orders" );
	Clear ( "#CustomerFilter, #StatusFilter, #ItemFilter, #WarehouseFilter, #DepartmentFilter" );
	GotoRow ( "#List", "Memo", id );
	Click ( "#FormDocumentInvoiceCreateBasedOn" );
	With ( "Invoice (cr*" );
	Set ( "#Memo", id );
	Click ( "#FormPost" );
	Close ();
	
	Call ( "Common.StampData", id );
	
EndProcedure
