// Create and print regular Quote

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2D193AF9" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/list/Document.Quote");
p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = id;
Call("Common.Find", p);
Click("#FormChange");
With ();
Pick ( "#VATUse", "Included in Price" );
Click ( "#FormDataProcessorPrintQuote" );
With();
Put("#Language", "Default");
Click("#FormOK");
With ();
Run ( "VATincluded" );
Close ();
With ();
Pick ( "#VATUse", "Excluded from Price" );
Click ( "#FormDataProcessorPrintQuote" );
With ();
Put("#Language", "Default");
Click("#FormOK");
With();
Run ( "VATNotincluded" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Item1", "Item1 " + ID );
	p.Insert ( "Item2", "Item2 " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Warehouses.Create", p );

	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	Call ( "Catalogs.Items.Create", p );

	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );

	#region createQuote
	Commando ( "e1cib/data/Document.Quote" );
	With ( "Quote (create)" );
	Put ( "#Customer", Env.Customer );
	tomorrow = Format ( CurrentDate () + 86400, "DLF=D" );
	Put ( "#DeliveryDate", tomorrow );
	Put ( "#DueDate", tomorrow );
	Put ( "#Warehouse", Env.Warehouse );
	PUt ( "#Memo", id );
	
	Click ( "#ItemsAdd" );
	Put ( "#ItemsItem", Env.Item1 );
	Activate ( "#ItemsFeature" ).Create ();
	With ();
	Set ( "#Description", Call ( "Common.GetID" ) );
	Click ( "#FormWriteAndClose" );
	
	With ();
	Items = Get ( "#Items" );
	
	Put ( "#ItemsPrice", "100" );
	Put ( "#ItemsQuantity", "5" );
	
	Click ( "#ItemsAdd" );
	Put ( "#ItemsItem", Env.Item2 );
	Put ( "#ItemsPrice", "200" );
	Put ( "#ItemsDiscountRate", 10 );
	Put ( "#ItemsQuantity", "10" );
	Set ( "#Memo", id );
	Click ( "#JustSave" );
	Close ();
	#endregion

	RegisterEnvironment ( id );

EndProcedure
