// 1. Create Sales Order
// 2. Create Payment
// 3. Create Adjust debt
// 4. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28C27532" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Adjust Customer Debts
// *************************
Commando ( "e1cib/list/Document.AdjustDebts" );
list = With ( "Adjust Customers Debts" );
Put ( "#CustomerFilter", env.Customer );
try
	Click ( "#FormChange" );
	form = With ( "Adjust Customer Debts #*" );
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	Click ( "#FormCreate" );
	form = With ( "Adjust Customer Debts (create)" );
endtry;

if ( Fetch  ( "#Reversal" ) = "Yes" ) then
	Click ( "#Reversal" );
endif;	

Put ( "#Option", "Customer" );
Put ( "#Receiver", env.Customer );

Put ( "#Amount", "1070" );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
records = With ( "Records: Adjust Customer Debts*" );
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
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
	p.TaxGroup = "California";
	p.SkipAddress = true;
	p.ClearTerms = true;
	p.CloseAdvances = false;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
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
	
	// ***********************************
	// Roles: Division head
	// ***********************************

	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	user = Call ( "Common.User" );
	Set ( "#User", user );
	Pick ( "#Role", "Department Head" );
	Set ( "#Department", Env.Department );
	CurrentSource.GotoNextItem ();
	Click ( "#Apply" );
	
	// *************************
	// Create Sales Order
	// *************************
	
	Commando ( "e1cib/data/Document.SalesOrder" );
	With ();
	Put ( "#Customer", Env.Customer );
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
	Click ( "#FormSendForApproval" );
	With ();
	Click ( "Yes" );

	// ***********************************
	// Open list and approve SO
	// ***********************************

	Commando ( "e1cib/list/Document.SalesOrder" );
	//DebugStart ();
	
	salesOrders = With ();
	Set ( "#CustomerFilter", env.Customer );
	Next ();
	Click ( "#FormChange" );
	form = With ();
	Click ( "#FormCompleteApproval" );

	With ( DialogsTitle );
	Click ( "Yes" );

	// *************************
	// Create Payment
	// *************************
	
	Commando ( "e1cib/command/Document.Payment.Create" );
	form = With ( "Customer Payment (cr*" );
	
	Put ( "#Customer",  Env.Customer );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", "1070" );
	Put ( "#Account", "2411" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Invoice
	// *************************
	
	With ( salesOrders );
	Click ( "#FormChange" );
	With ( "Sales Order #*" );
	Click ( "#FormInvoice" );
	
	With ( "Invoice (cr*" );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure