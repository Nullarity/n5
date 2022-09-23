// 1. Create 2 Invoice
// 2. Create Payment (debt)
// 3. Check change

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0TW" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Payment
// *************************
Commando ( "e1cib/data/Document.Payment" );
With ();
Put ( "#Customer", env.Customer );
Put ( "#Amount", "3000" );
Click ( "#UnmarkAll" );
Click ( "#MarkAll" );
if ( Fetch ( "#ContractAmount" ) <> "3,000" ) then
	Stop ( "Contract Amount must be 3000" );
endif;
Click ( "#UnmarkAll" );
Assert ( Fetch ( "#Info" ), "Info label should be visible" ).Contains ( "Payment Amount is 3,000.00 MDL" );

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
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Invoice
	// *************************
	
	Commando ( "e1cib/command/Document.Invoice.Create" );
	form = With ();
	
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
	// Create Invoice
	// *************************
	
	Commando ( "e1cib/command/Document.Invoice.Create" );
	form = With ();
	
	Put ( "#Customer", Env.Customer );
	
	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();
	
	Put ( "#ServicesAmount", "2000", table );
	
	Put ( "#Department", Env.Department );
	
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure
