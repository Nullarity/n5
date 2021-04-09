
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25CFD6BF" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.InternalOrder" );
With ( "Internal Order (cr*" );

table = Get ( "#Services" );
Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Item );
Next ();

// Calc without VAT
Set ( "#ServicesQuantity", 2, table );
Set ( "#ServicesPrice", 50, table );
Check ( "#ServicesAmount", 100, table );

// Set VAT use = Included in Price
Put ( "#VATUse", "Included in Price" );
Check ( "#ServicesVATCode", "20%", table );
Check ( "#ServicesVAT", 16.67, table );
Check ( "#VAT", 16.67 );

// Set VAT use = Excluded from Price
Put ( "#VATUse", "Excluded from Price" );
Check ( "#ServicesVAT", 20, table );
Check ( "#VAT", 20 );

Set ( "#ServicesAmount", 150, table );
Check ( "#VAT", 30 );
Check ( "#Amount", 180 );

Set ( "#ServicesQuantity", 1, table );
Check ( "#VAT", 15 );
Check ( "#Amount", 90 );

Set ( "#ServicesPrice", 120, table );
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
