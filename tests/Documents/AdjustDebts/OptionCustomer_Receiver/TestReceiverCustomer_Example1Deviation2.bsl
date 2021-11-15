// 1. Create Overpayment ( advance ) 
// 2. Create Adjust debt
// 3. Check movemnts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2811D232" );
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

Put ( "#Type", "Advance" );
Put ( "#Option", "Customer" );
Put ( "#Receiver", env.Customer );
Put ( "#ReceiverContract", "Receiver" );

Put ( "#Amount", "1500" );
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
	p.Insert ( "Department", "Administration" );
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
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Contract Receiver
	// *************************

	Commando ( "e1cib/list/Catalog.Organizations" );
	With ();
	p = Call ( "Common.Find.Params" );
	p.What = Env.Customer;
	p.Where = "Name";
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Click ( "Contracts", GetLinks () );
	With ( "Contracts" );
	Click ( "#FormCreate" );
	With ();
	Put ( "#Description", "Receiver" );
	Put ( "#CustomerPayment", "Cash" );
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
	// Create Payment
	// *************************
	
	Commando ( "e1cib/command/Document.Payment.Create" );
	form = With ( "Customer Payment (cr*" );
	
	Put ( "#Customer",  Env.Customer );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", "1500" );
	Put ( "#Account", "10400" );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure