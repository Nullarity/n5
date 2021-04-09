Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/data/Document.IntangibleAssetsTransfer" );
form = With ( "Intangible Assets Transfer (create)" );

Put ( "#Sender", Env.Sender );
Put ( "#Responsible", Env.Responsible );
Put ( "#Receiver", Env.Receiver );
Put ( "#Accepted", Env.Accepted );

first = true;
table = Activate ( "#ItemsTable" );
for each row in Env.Items do
	if ( first ) then
		first = false;
	else
		Click ( "#ItemsTableAdd" );
	endif;
	Put ( "#ItemsItem", row.Name, table );
enddo;

Click ( "#FormWrite" );
Click ( "#FormDocumentIntangibleAssetsTransferInvoice" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618536199#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
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
	if ( Call ( "Common.DataCreated", id ) ) then
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
	// Create Assets
	// ***********************
	
	for each item in Env.Items do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = item.Name;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;

	Call ( "Common.StampData", id );

EndProcedure
