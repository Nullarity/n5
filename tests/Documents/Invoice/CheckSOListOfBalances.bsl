// Create SO
// Create Payment
// Create Invoice
// Check Balance field in the list of Goods

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BFC8F01" );
env = getEnv ( id );
createEnv ( env );

// Open SO list and navigate to created SO
Commando ( "e1cib/list/Document.SalesOrder" );
Clear ( "#CustomerFilter, #StatusFilter, #ItemFilter, #WarehouseFilter, #DepartmentFilter" );
GotoRow ( "#List", "Memo", id );

// Wait until goods table is filled and check results
Pause ( 1 );
CheckTable ( "
|#Goods
|# | Ordered | Shipped | Balance
|1 | 3       | 1       | 2
|" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "SODate", date - 86400 );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Service ", "Service " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region CreateCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion
	
	#region CreateService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region CreateSO
	p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
	p.Date = Env.SODate;
	p.Customer = Env.Customer;
	p.Terms = "Main";
	p.Memo = Env.ID;
	row = Call ( "Documents.SalesOrder.CreateApproveOneUser.ServicesRow" );
	row.Item = "_Service: " + id;
	row.Quantity = 3;
	row.Price = 100;
	row.Performer = "None";
	p.Services.Add ( row );
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p );
	#endregion
	
	#region CreatePayment
	Commando ( "e1cib/list/Document.SalesOrder" );
	Clear ( "#CustomerFilter, #StatusFilter, #ItemFilter, #WarehouseFilter, #DepartmentFilter" );
	GotoRow ( "#List", "Memo", id );
	Click("#FormDocumentPaymentCreateBasedOn");
	With ();
	Click ( "#FormPostAndClose" );
	#endregion

	#region CreateInvoice
	With ();
	Click ( "#FormDocumentInvoiceCreateBasedOn" );
	With ();
	Set ( "#Services / #ServicesQuantity [ 1 ]", 1 );
	Set ( "#Memo", id );
	Click ( "#FormPost" );
	Close ();
	#endregion

	RegisterEnvironment ( id );

EndProcedure
