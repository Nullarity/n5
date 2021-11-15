// different customers
// 1. Create Invoice ( debt ) by Customer
// 1. Create Payment ( advance ) by Receiver
// 2. Create Adjust debt
// 3. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2864E3F4" );
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

Put ( "#Type", "Debt" );
Put ( "#Option", "Customer" );
Put ( "#Receiver", env.Receiver );

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
	p.Insert ( "Receiver", "Receiver " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Expense", "Expense " + ID );
	p.Insert ( "Department", "Department " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer, Receiver
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.TaxGroup = "California";
	p.ClearTerms = true;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Receiver;
	p.TaxGroup = "California";
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
	Put ("#Customer", Env.Customer );
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

	salesOrders = With ();
	Set ( "#CustomerFilter", env.Customer );
	Put ( "#StatusFilter", "Active" );
	
	Click ( "#FormChange" );
	With ();
	Click ( "#FormCompleteApproval" );

	With ( DialogsTitle );
	Click ( "Yes" );

	With ( salesOrders );
	Click ( "#FormChange" );
	With ( "Sales Order #*" );
	Click ( "#FormInvoice" );
	
	// *************************
	// Create Invoice
	// *************************
	
	With ( "Invoice (cr*" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Payment
	// *************************
	
	Commando ( "e1cib/command/Document.Payment.Create" );
	form = With ( "Customer Payment (cr*" );
	
	Put ( "#Customer",  Env.Receiver );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", "570" );
	Put ( "#Account", "10400" );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure