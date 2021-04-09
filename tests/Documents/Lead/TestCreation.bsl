// Create a new Lead

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "282F5BA2" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Catalog.Leads.Create");
With();

// Set first name & last name
Set("#FirstName", env.FirstName);
Set("#LastName", env.LastName);

// Add item
Click("#ItemsTableAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantityPkg", 5);
Set("#ItemsQuantity", 50);
Set("#ItemsPrice", 3);
Next();
Set("#ItemsAmount[1]", 300, Get("#ItemsTable"));

// Add service
Click("#ServicesAdd");
Set("#ServicesItem", env.Service);
Set("#ServicesQuantity", 50);
Set("#ServicesPrice", 3);
Next();
Set("#ServicesAmount[1]", 300, Get("#Services"));

Click("#FormWrite");

Disconnect ();

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "FirstName", "First " + ID );
	p.Insert ( "LastName", "Last " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item & Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
