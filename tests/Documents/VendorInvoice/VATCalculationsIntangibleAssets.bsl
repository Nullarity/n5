﻿
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25E1BFBE" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.VendorInvoice" );
form = With ( "Vendor Invoice (cr*" );

Put ( "#VATUse", "Excluded from Price" );

Click ( "#IntangibleAssetsAdd" );
With ( "Intangible Asset" );

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
	p.Insert ( "Item", "Intangible Asset " + ID );
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
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.IntangibleAssets.Create", p );

	RegisterEnvironment ( id );

EndProcedure
