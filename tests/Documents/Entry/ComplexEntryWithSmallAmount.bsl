// Create Entry
// Create two Dr records
// Create two Cr records
// Post and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2863B1DB" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.Entry.Create");
form = With();

// Create record 1 with Dr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountDr", "11000");
Put("#DimDr1", env.Customer1);
Set("#Amount", 5);
Click("#FormOK");

// Create record 2 with Dr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountDr", "11000");
Put("#DimDr1", env.Customer2);
Set("#Amount", 5);
Click("#FormOK");

// Create record 1 with Cr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountCr", "2171");
Put("#DimCr1", env.Item1);
Put("#QuantityCr", 0.001);
Set("#Amount", 0.01);
Click("#FormOK");

// Create record 2 with Cr
With(form);
Click("#RecordsAdd");
With();
Put("#AccountCr", "2171");
Put("#DimCr1", env.Item2);
Put("#QuantityCr", 5);
Set("#Amount", 9.99);
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
	p.Insert ( "Customer1", "Customer1 " + ID );
	p.Insert ( "Customer2", "Customer2 " + ID );
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
	p.Description = Env.Customer1;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	p.Description = Env.Customer2;
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
