// 1. Create Overpayment (advance)
// 2. Create Invoice (debt)
// 3. Adjust Invoice (-debt = advance)
// 4. Adjust debt
// 5. Check movemnts
// 6. Adjust advances
// 7. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "285E7A80" );
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
Put ( "#Option", "Expenses" );
PUt ( "#Account", "8111" );
PUt ( "#Dim1", env.Expense );
PUt ( "#Dim2", env.Department );

Put ( "#Amount", "2000" );
Click ( "#FormPost" );

IgnoreErrors = true;

error = "Amount due is not equal to Adjustment amount";
if ( FindMessages ( error ).Count () = 0 ) then
	Stop ( "Error: " + error + " must be shown" );
endif;

IgnoreErrors = false;
Put ( "#Amount", "1070" );

Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
records = With ( "Records: Adjust Customer Debts*" );
CheckTemplate ( "#TabDoc" );
Close ( records );

With ( form );
Click ( "#FormUndoPosting" );

Put ( "#Type", "Advance" );

Put ( "#Option", "Income" );
PUt ( "#Account", "70100" );

Put ( "#Amount", "2500" );
Click ( "#FormPost" );
Run ( "CheckAdvance" );

With ( form );
Click ( "#FormCopy" );
copy = "Adjust Customer Debts (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
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
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.TaxGroup = "California";
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
	
	// *************************
	// Create Payment
	// *************************
	
	Commando ( "e1cib/command/Document.Payment.Create" );
	form = With ( "Customer Payment (cr*" );
	
	Put ( "#Customer", Env.Customer );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", "500" );
	Put ( "#Account", "10400" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Invoice
	// *************************
	
	Commando ( "e1cib/command/Document.Invoice.Create" );
	form = With ( "Invoice (cr*" );
	
	Put ( "#Customer", Env.Customer );
	
	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();
	
	Put ( "#ServicesAmount", "1000", table );
	
	Put ( "#Department", Env.Department );
	
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Invoice (negative)
	// *************************
	
	Commando ( "e1cib/command/Document.Invoice.Create" );
	form = With ( "Invoice (cr*" );
	
	Put ( "#Customer", Env.Customer );
	
	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();

	Put ( "#ServicesAmount", "-2000", table );
	
	Put ( "#Department", Env.Department );
	
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure
