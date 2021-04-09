
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25CFD6BF" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.Startup" );
form = With ( "LVI Startup (cr*" );

Click ( "#ShowPrices" );

Put ( "#VATUse", "Excluded from Price" );

Click ( "#ItemsAdd" );
With ( "LVI" );

Put ( "#Item", env.Item );
Put ( "#Amount", "100" );

Next ();

Check ( "#VAT", 20 );
Check ( "#Total", 120 );

Put ( "#VAT", "50" );
Next ();
Check ( "#Total", 150 );

Put ( "#Amount", "50" );
Next ();
Check ( "#VAT", 10 );
Check ( "#Total", 60 );

Put ( "#Price", "10" );
Next ();
Check ( "#VAT", 2 );
Check ( "#Total", 12 );

Put ( "#VAT", "20" );
Next ();
Check ( "#Total", 30 );

Click ( "#FormOK" );

With ( form );

Check ( "#VAT", 20 );
Check ( "#Amount", 30 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Fixed Asset " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
