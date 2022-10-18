Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// *************************
// Create Payments
// *************************

Commando ( "e1cib/list/Document.Refund" );
With ();
Click ( "#FormCreate" );
With ();
Put ( "#Customer", env.Customer );
Set ( "#Amount", 100 );
Click("#Payments / #PaymentsPay[1]");
Click ( "#FormPost" );

// Check postings
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ()
	
	date = CurrentDate ();
	id = Call ( "Common.ScenarioID", "A0W5" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Customer", "_Customer: " + id );
	p.Insert ( "SODate", date - 86400 );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.Terms = "Due on receipt";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create SO
	// *************************
	
	p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
	p.Date = Env.SODate;
	p.Customer = Env.Customer;
	p.Terms = "Due on receipt";
	p.Memo = Env.ID;
	row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
	row.Item = "_Service: " + id;
	row.Quantity = 1;
	row.Price = 100;
	row.Performer = "None";
	p.Services.Add ( row );
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p );
	
	// *************************
	// Create & post Payment
	// *************************

	Commando ( "e1cib/list/Document.SalesOrder" );
	With ( "Sales Orders" );
	Clear ( "#CustomerFilter, #StatusFilter, #ItemFilter, #WarehouseFilter, #DepartmentFilter" );
	GotoRow ( "#List", "Memo", id );
	Click ( "#FormChange" );
	With ();
	Click ( "#FormPayment" );
	With ();
	Set ( "#Amount", 100 );
	Click ( "#FormPost" );
	CloseAll ();
	
	RegisterEnvironment ( id );
	
EndProcedure
