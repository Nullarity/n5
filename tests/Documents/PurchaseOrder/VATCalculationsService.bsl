
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25E1A143" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.PurchaseOrder" );
With ( "Purchase Order (cr*" );

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
Check ( "#Amount", 120 );

Set ( "#ServicesDiscountRate", 50, table );
Check ( "#VAT", 10 );
Check ( "#Amount", 60 );

Set ( "#ServicesDiscount", 10, table );
Check ( "#VAT", 18 );
Check ( "#Amount", 108 );

Set ( "#ServicesAmount", 100, table );
Check ( "#VAT", 20 );
Check ( "#Amount", 120 );

Set ( "#ServicesQuantity", 1, table );
Check ( "#VAT", 8.89 );
Check ( "#Amount", 53.34 );

Set ( "#ServicesPrice", 100, table );
Check ( "#VAT", 18 );
Check ( "#Amount", 108 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Service " + ID );
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
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

	RegisterEnvironment ( id );

EndProcedure
