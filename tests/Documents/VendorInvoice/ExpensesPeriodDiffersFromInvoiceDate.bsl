// Create Invoice
// Add Service
// Set Expense Period a month back
// Save & Post
// Check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27228562" );
env = getEnv ( id );
createEnv ( env );

// Create Invoice
Commando ( "e1cib/data/Document.VendorInvoice" );
With ( "Vendor Invoice (cr*" );
Put ( "#Vendor", env.Vendor );

// Set Expense Period a month back
expensesPeriod = env.ExpensesPeriod;
Set ( "#ExpensesPeriod", Format(expensesPeriod, "DLF=D") );

// Add Service
Click ( "#ServicesAdd" );
Put ( "#ServicesItem", env.Service );
Activate ( "#ServicesPrice" );
Set ( "#ServicesPrice", 100 );
Activate ( "#ServicesExpense" );
Put ( "#ServicesExpense", "Others" );

// Save & Post
Click ( "#FormPost" );

// Check records
Click ( "#FormReportRecordsShow" );
With ( "Records: Vendor Inv*" );
recordPeriod = Fetch ( "#TabDoc [ R8C1 ]" );
if ( Date ( recordPeriod + " 12:00:00 AM" ) <> BegOfDay (EndOfMonth(expensesPeriod))) then
	Stop ( "Expenses record date should be a month back with Vendor Invoice document date" );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "ExpensesPeriod", BegOfDay ( AddMonth ( CurrentDate (), -1 ) ) );
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
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
