Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/data/Document.IntangibleAssetsTransfer" );
form = With ( "Intangible Assets Transfer (create)" );

table = Activate ( "#ItemsTable" );
table.EndEditRow ();

Set ( "#Sender", Env.Sender );
Set ( "#Responsible", Env.Responsible );
Set ( "#Receiver", Env.Receiver );
Put ( "#Accepted", Env.Accepted );

Click ( "#ItemsFill" );
Click ( "Yes" );

//Click ( "#ItemsTableDelete" ); // Delete empty row

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "272B31B3#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "Warehouse", "_Warehouse: " + id );
	env.Insert ( "ReceiveAccount", "70100" );
	env.Insert ( "Sender", "_Department Sender " + id );
	env.Insert ( "Receiver", "_Department Receiver " + id );
	env.Insert ( "Responsible", "_Responsible " + id );
	env.Insert ( "Accepted", "_Accepted " + id );
	
	items = new Array ();
	items.Add ( newItem ( "_Item " + id, 1, 150 ) );
	items.Add ( newItem ( "_Item, pkg " + id, 1, 250 ) );
	env.Insert ( "Items", items );
	return env;

EndFunction

Function newItem ( Name, Quantity, Amount )

	p = new Structure ( "Name, Quantity, Amount" );
	p.Name = Name;
	p.Quantity = Quantity;
	p.Amount = Amount;
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************
	// Create Sender, Responsible
	// ***********************

	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Sender;
	Call ( "Catalogs.Departments.Create", p );

	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );

	// ***********************
	// Create Receiver, Accepted
	// ***********************

	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Receiver;
	Call ( "Catalogs.Departments.Create", p );

	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Accepted;
	Call ( "Catalogs.Employees.Create", p );

	// ***********************
	// Create Warehouse
	// ***********************

	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );

	// ***********************
	// Create Assets
	// ***********************
	
	for each item in Env.Items do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = item.Name;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	// ***********************
	// Receive Items
	// ***********************

	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Account = Env.ReceiveAccount;
	p.Warehouse = Env.Warehouse;
	p.Date = Env.Date - 86400;
	assets = p.IntangibleAssets;
	for each item in Env.Items do
		row = Call ( "Documents.ReceiveItems.Receive.Asset" );
		row.Asset = item.Name;
		row.Amount = item.Amount;
		row.Department = Env.Sender;
		row.Responsible = Env.Responsible;
		assets.Add ( row );
	enddo;
	Call ( "Documents.ReceiveItems.Receive", p );

	RegisterEnvironment ( id );

EndProcedure
