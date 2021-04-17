// 1. Create Invoice ( debt ) by customer contract
// 2. Create VendorInvoice ( debt ) by vendor contract
// 3. Create Adjust debt
// 4. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286653C3" );
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
Put ( "#Option", "Vendor" );
Put ( "#Receiver", env.Customer );
Put ( "#ReceiverContract", "Vendor" );

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
	p.Insert ( "Customer", "Customer/Vendor " + ID );
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
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ();
	Put ( "#Description", env.Customer );
	Click ( "#Customer" );
	Click ( "#Vendor" );
	Put ( "#TaxGroup", "California" );
	Click ( "#FormWrite" );
	
	Click ( "Contracts", GetLinks () );
	With ( "Contracts" );
	Click ( "#FormChange" );
	contracts = With ();
	Click ( "#Vendor" );
	Clear ( "#CustomerTerms" );
	Put ( "#Description", "Customer" );
	Put ( "#CustomerPayment", "Cash" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Contract Receiver
	// *************************

	With ( "Contracts" );
	Click ( "#FormCreate" );
	With ();
	Click ( "#Customer" );
	Put ( "#Description", "Vendor" );
	Clear ( "#VendorTerms" );
	Put ( "#VendorPayment", "Cash" );
	Click ( "#FormWriteAndClose" );
	
	With ( "Contracts" );
	Click ( "Main", GetLinks () );
	With ();
	Put ( "#VendorContract", "Vendor" );
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
	Set ("#Customer", Env.Customer );
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
	// Create PurchaseOrder and generate Vendor invoice
	// *************************
	
	Commando ( "e1cib/data/Document.PurchaseOrder" );
	With ();
	Put ("#Vendor", Env.Customer );
	Put ( "#Memo", id );

	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();
	Put ( "#ServicesAmount", "500", table );

	// Payments
	table = Get ( "#Payments" );
	Click ( "#PaymentsAdd" );
	Put ( "#PaymentsPaymentOption", "nodiscount#" );
	Next ();
	
	Put ( "#Department", Env.Department );
	Click ( "#FormPost" );
	
	Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
	With ();
	table = Get ( "#Services" );
	//Click ( "#ServicesChange" );
	Put ( "#ServicesAccount", "8111", table );
	Next ();
	Put ( "#ServicesExpense", Env.Expense, table );

	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );	
EndProcedure