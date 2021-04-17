Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
CloseAll ();

// ***********************************
// Open Report
// ***********************************

p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.Entries";
p.Title = "Entries*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = env.date;
item.ValueTo = env.date;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Account";
item.Value = env.accountDr;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Warehouses";
item.Value = env.warehouseName;
filters.Add ( item );

p.Filters = filters;

With ( Call ( "Common.Report", p ) );
CheckTemplate ( "#Result" );

Function getEnv ()

	env = new Structure ();
	id = Call ( "Common.ScenarioID", "286F8219" );
	date = date ( 2017, 1, 31 );//CurrentDate ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", date );
	env.Insert ( "Tomorrow", date + 86400 );
	env.Insert ( "WarehouseName", "_Entries Report: " + id );
	env.Insert ( "ItemName", "_Test Entries Report#" + id );
	env.Insert ( "AccountDr", "12100" );
	env.Insert ( "AccountCr", "00000" );
	env.Insert ( "Amount", "-700" );
	env.Insert ( "QuantityDr", "-5" );
	return env;

EndFunction

Procedure createEnv ( Env )	
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;

	// ***********************************
	// Create Warehouse
	// ***********************************

	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Warehouses;
	p.Description = Env.warehouseName;
	p.CreationParams = Env.warehouseName;
	Call ( "Common.CreateIfNew", p );

	// ***********************************
	// Create Item
	// ***********************************

	Call ( "Catalogs.Items.CreateIfNew", Env.itemName );

	// ***********************************
	// Create Entry
	// ***********************************

	p = Call ( "Documents.Entry.Create.Params" );

	// Dr

	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = Env.accountDr;
	row.DimDr1 = Env.itemName;
	row.DimDr2 = Env.warehouseName;
	row.QuantityDr = Env.quantityDr;

	// Cr

	row.AccountCr = Env.accountCr;

	row.Amount = Env.amount;
	p.Records.Add ( row );
	p.Date = Env.Date;
	Call ( "Documents.Entry.Create", p );
	
	Call ( "Common.StampData", id );


EndProcedure
