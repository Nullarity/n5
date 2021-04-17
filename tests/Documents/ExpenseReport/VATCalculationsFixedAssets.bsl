
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25E1B5C2" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.ExpenseReport" );
form = With ( "Expense Report (cr*" );

Put ( "#VATUse", "Excluded from Price" );

Click ( "#FixedAssetsAdd" );
With ( "Fixed Asset" );

Put ( "#Item", env.Item );
Put ( "#Amount", "100" );

Next ();

Check ( "#VAT", 20 );
Check ( "#Total", 120 );

Put ( "#VAT", "50" );
Next ();
Check ( "#Total", 150 );

Click ( "#FormOK" );

With ( form );

Check ( "#VAT", 50 );
Check ( "#Amount", 150 );

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
