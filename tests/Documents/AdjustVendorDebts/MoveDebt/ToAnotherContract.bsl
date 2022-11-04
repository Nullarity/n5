// - Create Purchase Order
// - Create Vendor Invoice
// - Create Adjust Vendor Debt
// - Check movemnts
// - Check Reconciliation Report

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "B0YX" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Adjust Vendor Debts
// *************************

Commando ( "e1cib/list/Document.AdjustVendorDebts" );
list = With ();
Put ( "#VendorFilter", env.Vendor );
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
	Put ( "#Option", "Vendor" );
	Put ( "#Receiver", env.Vendor );
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
	p.Insert ( "Vendor", "Vendor " + ID );
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
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Terms = "Due on receipt";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Contract2
	// *************************
	
	Commando ( "e1cib/list/Catalog.Organizations" );
	With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = Env.Vendor;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Click ( "Contracts", GetLinks () ); 
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Description", Env.Contract2 );
	Click ( "#VendorAdvances" );
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
	Put ( "#Vendor", Env.Vendor );
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
	Click ( "#FormVendorInvoice" );
	With ();
	table = Get ( "#Services" );
	Set ( "#ServicesPrice [ 1 ]", 400, table ); 
	Set ( "#ServicesExpense [ 1 ]", Env.Expense, table ); 
	Set ( "#ServicesAccount [ 1 ]", "8111", table ); 
	Click ( "#FormPostAndClose" );
	
	Close ( purchaseOrder );
	
	RegisterEnvironment ( id );
	
EndProcedure