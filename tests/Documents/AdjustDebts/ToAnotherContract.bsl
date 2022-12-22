// TODO
return;

// - Create Purchase Order
// - Create Customer Invoice
// - Create Adjust Customer Debt
// - Check movemnts
// - Check Reconciliation Report

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A11R" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Adjust Customer Debts
// *************************

Commando ( "e1cib/list/Document.AdjustCustomerDebts" );
list = With ();
Put ( "#CustomerFilter", env.Customer );
try
	Click ( "#FormChange" );
	form = With ();
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	Click ( "#FormCreate" );
	form = With ();
	Put ( "#Option", "Customer" );
	Put ( "#Receiver", env.Customer );
	Put ( "#ReceiverContract", env.Contract2 );
	Click ( "#Reversal" );
	Put ( "#Amount", 400 );
	AccountingReceiver = Get ( "#AccountingReceiver" );
	Click ( "#AccountingReceiverAdd" );
	Set ( "#AccountingReceiverAmount", 400, AccountingReceiver );
endtry;

Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
records = With ();
CheckTemplate ( "#TabDoc" );
Run ( "CheckReconciliation", env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Contract2", "General2" );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Expense", "Expense " + ID );
	p.Insert ( "Department", "Administration " + ID );
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
	// Create Contract2
	// *************************
	
	Commando ( "e1cib/list/Catalog.Organizations" );
	With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = Env.Customer;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Click ( "Contracts", GetLinks () ); 
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Description", Env.Contract2 );
	Click ( "#CustomerAdvances" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create PurchaseOrder
	// *************************
	
	Commando ( "e1cib/data/Document.PurchaseOrder" );
	purchaseOrder = With ();
	Put ( "#Customer", Env.Customer );
	Put ( "#Memo", id );

	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();
	Put ( "#ServicesAmount", "1000", table );
	Put ( "#Department", Env.Department );
	Click ( "#FormPost" );
	
	// *************************
	// Create Invoice
	// *************************
	
	With ( purchaseOrder );
	Click ( "#FormCustomerInvoice" );
	With ();
	table = Get ( "#Services" );
	Set ( "#ServicesPrice [ 1 ]", 400, table ); 
	Set ( "#ServicesExpense [ 1 ]", Env.Expense, table ); 
	Set ( "#ServicesAccount [ 1 ]", "8111", table ); 
	Click ( "#FormPostAndClose" );
	
	Close ( purchaseOrder );
	
	RegisterEnvironment ( id );
	
EndProcedure