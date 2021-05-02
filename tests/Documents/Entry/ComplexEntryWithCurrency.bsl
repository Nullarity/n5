// Create Entry
// Create record with Dr and Cr
// Create record with Dr
// Create record 1 with Cr
// Create record 2 with Cr
// Post and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28524F53" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.Entry.Create");
form = With();

// Create record with Dr and Cr
Click("#RecordsAdd");
With();
Put("#AccountDr", "0000");
Put("#AccountCr", "0000");
Set("#Amount", 1000);
Click("#FormOK");

// Create record with Dr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountDr", "11000");
Put("#DimDr1", env.Customer);
Set("#Amount", 1500);
Click("#FormOK");

// Create record 1 with Cr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountCr", "2171");
Put("#DimCr1", env.Item1);
Put("#QuantityCr", 3);
Set("#Amount", 750);
Click("#FormOK");

// Create record 2 with Cr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountCr", "2171");
Put("#DimCr1", env.Item2);
Put("#QuantityCr", 5);
Set("#Amount", 750);
Click("#FormOK");

// Post
With(form);
Click("#FormPost");

// Test records
Click("#FormReportRecordsShow");
With();
Call("Common.CheckLogic", "#TabDoc");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Item1", "Item1 " + ID );
	p.Insert ( "Item2", "Item2 " + ID );
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
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	Call ( "Catalogs.Items.Create", p );
	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
