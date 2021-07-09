
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25CFD6BF" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.PurchaseOrder" );
With ( "Purchase Order (cr*" );

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

Set ( "#ItemsDiscountRate", 50, table );
Check ( "#VAT", 10 );
Check ( "#Amount", 60 );

Set ( "#ItemsDiscount", 10, table );
Check ( "#VAT", 18 );
Check ( "#Amount", 108 );

Set ( "#ItemsAmount", 100, table );
Check ( "#VAT", 20 );
Check ( "#Amount", 120 );

Set ( "#ItemsQuantityPkg", 1, table );
Check ( "#VAT", 8.89 );
Check ( "#Amount", 53.34 );

Set ( "#ItemsPrice", 100, table );
Check ( "#VAT", 18 );
Check ( "#Amount", 108 );

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
