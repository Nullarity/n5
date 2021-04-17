Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25EA9A16" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.AssetsWriteOff" );
With ( "Assets Write Off (cr*" );
Click ( "#ShowPrices" );

table = Get ( "#Items" );

Click ( "#ItemsAdd" );

Put ( "#ItemsItem", env.Item, table );
Next ();
Set ( "#ItemsAmount", 100, table );

Put ( "#VATUse", "Included in Price" );
Check ( "#VAT", 16.67 );
Check ( "#Amount", 100 );

Put ( "#VATUse", "Excluded from Price" );
Check ( "#VAT", 20 );
Check ( "#Amount", 120 );

Set ( "#ItemsAmount", 200, table );
Check ( "#VAT", 40 );
Check ( "#Amount", 240 );

Set ( "#ItemsVAT", 20, table );
Check ( "#Amount", 220 );

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
	
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.FixedAssets.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
