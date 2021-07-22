
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25CFD6BF" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.InternalOrder" );
With ( "Internal Order (cr*" );

table = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );

Put ( "#ItemsItem", env.Item );
Next ();

// Calc without VAT
Set ( "#ItemsQuantityPkg", 2, table );
Set ( "#ItemsPrice", 50, table );
Check ( "#ItemsAmount", 100, table );

// Set VAT use = Included in Price
Put ( "#VATUse", "Included in Price" );
Check ( "#ItemsVATCode", "20%", table );
Check ( "#ItemsVAT", 16.67, table );
Check ( "#VAT", 16.67 );

// Set VAT use = Excluded from Price
Put ( "#VATUse", "Excluded from Price" );
Check ( "#ItemsVAT", 20, table );
Check ( "#VAT", 20 );

Set ( "#ItemsAmount", 150, table );
Check ( "#VAT", 30 );
Check ( "#Amount", 180 );

Set ( "#ItemsQuantityPkg", 1, table );
Check ( "#VAT", 15 );
Check ( "#Amount", 90 );

Set ( "#ItemsPrice", 120, table );
Check ( "#VAT", 24 );
Check ( "#Amount", 144 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );

	RegisterEnvironment ( id );

EndProcedure
