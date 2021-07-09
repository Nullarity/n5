Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.Assembling );
list = With ();
Put ( "#WarehouseFilter", env.Warehouse );

table = Get ( "#List" ); 
count = Call ( "Table.Count", table );
for i = 1 to count do
	if ( i = 1 ) then
		table.GotoFirstRow ();
	else
		table.GotoNextRow ();	
	endif;	
	Click ( "#FormSetDeletionMark" );
	Click ( "Yes", "1?:*" );
	Pause ( __.Performance * 2 );
enddo;

With ( list );
Click ( "#FormCreate" );
form = With ( "Assembling (create)" );

Set ( "#Warehouse", env.Warehouse );
Put ( "#Set", env.Set );
	
With ( form );
Set ( "#Quantity", "25" );

table = Activate ( "#Items" );
Call ( "Table.AddEscape", table );
for each row in Env.Items do
	Click ( "#ItemsAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;
Call ( "Table.CopyEscapeDelete", table );

// *************************
// Items Selection
// *************************

Call ( "Table.Clear", table );
Click ( "#ItemsSelectItems" );

selectionForm = With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;	

table = Get ( "#ItemsList" );

for i = 1 to 2 do
	row = Env.Items [ i - 1 ];
	GoToRow ( table, "Item", row.Item );
	table.Choose ();
	if ( i = 2 ) then // count packages
		With ( selectionForm );
		tablePackages = Get ( "#PackagesList" );
		tablePackages.Choose ();
	endif;
	With ( "Details" );
	Set ( "#Quantity", row.Quantity );
	Click ( "#FormOK" );
enddo;

With ( selectionForm );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );
isCont = env.AppIsCont;
Run ( ? ( isCont, "LogicCont", "Logic" ) );
With ( form );
Run ( "PrintForm" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = "#" + Call ( "Common.ScenarioID", "288225FF" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Date", CurrentDate () );
	p.Insert ( "Warehouse", "_Assembling Warehouse " + id );
	p.Insert ( "Expenses", "_Assembling " + id );
	isCont = Call ( "Common.AppIsCont" );
	p.Insert ( "Account", ? ( isCont, "7141", "8111" ) );
	p.Insert ( "AppIsCont", isCont );
 	p.Insert ( "Set", "_Set " + id );
	
	items = new Array ();
 	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item1: " + id;
	row.CountPackages = false;
	row.Quantity = "150";
	row.Price = "7";
	items.Add ( row );

	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item2, countPkg: " + id;
	row.CountPackages = true;
	row.Quantity = "65";
	row.Price = "70";
	items.Add ( row );
	p.Insert ( "Items", items );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create ReceiveItems
	// *************************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = Env.Date - 86400;
	p.Warehouse = Env.Warehouse;
	p.Account = Env.Account;
	p.Expenses = Env.Expenses;
 	p.Items = Env.Items;
	Call ( "Documents.ReceiveItems.Receive", p );
	
	// *************************
	// Create Set
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Set;
	p.CountPackages = false;
	Call ( "Catalogs.Items.Create", p );

	RegisterEnvironment ( id );

EndProcedure

