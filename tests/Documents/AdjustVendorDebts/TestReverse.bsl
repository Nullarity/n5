// 1. Create Purchase Order
// 2. Create Vendor Payment
// 3. Create Vendor Invoice
// 4. Create Adjust vendor debt
// 5. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28CBEE8F" );
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
endtry;

Put ( "#Option", "Vendor" );
Put ( "#Receiver", env.Vendor );
Put ( "#ReceiverContract", env.Contract2 );
if ( Fetch  ( "#Reversal" ) = "No" ) then
	Click ( "#Reversal" );
endif;	

Put ( "#Amount", "1070" );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
records = With ();
CheckTemplate ( "#TabDoc" );

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
	//p.TaxGroup = "California";
	//p.SkipAddress = true;
	p.ClearTerms = true;
	p.CloseAdvances = false;
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
	
	// Payments
	table = Get ( "#Payments" );
	Click ( "#PaymentsAdd" );
	Put ( "#PaymentsPaymentOption", "nodiscount#" );
	Next ();

	Put ( "#Department", Env.Department );
	Click ( "#FormPost" );
	
	// *************************
	// Create Vendor Payment
	// *************************
	
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	With ();
	
	Put ( "#Vendor",  Env.Vendor );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", "1070" );
	Put ( "#Account", "20000" );
	Put ( "#AdvanceAccount", "20000" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Invoice
	// *************************
	
	With ( purchaseOrder );
	Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
	With ();
	table = Get ( "#Services" );
	Set ( "#ServicesExpense [ 1 ]", Env.Expense, table ); 
	Set ( "#ServicesAccount [ 1 ]", "8111", table ); 
	Click ( "#FormPostAndClose" );
	
	Close ( purchaseOrder );
	
	RegisterEnvironment ( id );
	
EndProcedure