// Create: Item, Service, Organization, Contract
// Twice add Item and Service to contract
// Save contract and check errors

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0EV" );
env = getEnv ( id );
createEnv ( env );

// Create Organization
Commando ( "e1cib/data/Catalog.Organizations" );
With ( "Organizations (cr*" );
Set ( "#Description", env.Organization + " " + CurrentDate () );
Click ( "#Customer" );
Click ( "#Vendor" );
Click ( "#FormWrite" );

// Open Contract & Add Item and Service twice
Click("#CustomerPage");
Get ( "#CustomerContract" ).Open ();
With ( "General (Cont*" );

Click ( "#ItemsAdd" );
Put ( "#ItemsItem", env.Item );
Activate ( "#ItemsPrice" );
Set ( "#ItemsPrice", 5 );

Click ( "#ItemsAdd" );
Put ( "#ItemsItem", env.Item );
Activate ( "#ItemsPrice" );
Set ( "#ItemsPrice", 5 );


Click ( "#ServicesAdd" );
Put ( "#ServicesItem", env.Service );
Activate ( "#ServicesPrice" );
Set ( "#ServicesPrice", 5 );

Click ( "#ServicesAdd" );
Put ( "#ServicesItem", env.Service );
Activate ( "#ServicesPrice" );
Set ( "#ServicesPrice", 5 );
Next ();

// Try to save
Click ( "#FormWrite" );
if ( FindMessages ( "* duplicated" ).Count () = 2 ) then
	StandardProcessing = false;
else
	Stop ( "Error message about double items and services should be shown" );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Organization", "Organization " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
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
