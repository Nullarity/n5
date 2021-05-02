// Create two Entries: one for Today and the second for Tomorrow
// Generate Report today, tomorrow and check results

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "26BFDE68" );
env = getEnv ( id );
createEnv ( env );

generateReport ( Env, Env.Today );
CheckTemplate ( "#Result" );
Close ();
generateReport ( Env, Env.Tomorrow );
Run ( "InitialBalance" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	date = CurrentDate ();
	tomorrow = date + 86400;
	p.Insert ( "Today", date );
	p.Insert ( "Tomorrow", date + 86400 );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "AccountDr", "2171" );
	p.Insert ( "AccountCr", "0" );
	p.Insert ( "Amount", -700 );
	p.Insert ( "QuantityDr", -5 );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );

	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );

	// ***********************************
	// Create Entry
	// ***********************************

	p = Call ( "Documents.Entry.Create.Params" );

	// Dr

	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = Env.AccountDr;
	row.DimDr1 = Env.Item;
	row.DimDr2 = Env.Warehouse;
	row.QuantityDr = Env.QuantityDr;

	// Cr

	row.AccountCr = Env.AccountCr;

	row.Amount = Env.Amount;
	p.Records.Add ( row );
	row = Call ( "Documents.Entry.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure generateReport ( Env, Date )

	p = Call ( "Common.Report.Params" );
	p.Path = "Accounting / Analytic Transactions";
	p.Title = "Analytic Transactions*";
	filters = new Array ();

	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date;
	item.ValueTo = Date;
	filters.Add ( item );

	item = Call ( "Common.Report.Filter" );
	item.Name = "Analytics 1";
	item.Value = "Items";
	filters.Add ( item );

	item = Call ( "Common.Report.Filter" );
	item.Name = "Dimension 1";
	item.Value = Env.Item;
	filters.Add ( item );

	item = Call ( "Common.Report.Filter" );
	item.Name = "Analytics 2";
	item.Value = "Warehouses";
	filters.Add ( item );

	item = Call ( "Common.Report.Filter" );
	item.Name = "Dimension 2";
	item.Value = Env.Warehouse;
	filters.Add ( item );

	p.Filters = filters;
	With ( Call ( "Common.Report", p ) );

EndProcedure
