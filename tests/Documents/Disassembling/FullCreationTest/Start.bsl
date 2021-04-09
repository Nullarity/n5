Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Call ( "Catalogs.UserSettings.CostOnline", true );

// ***********************************
// Create Disassembling
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Disassembling );
Click ( "#FormCreate" );
form = With ( "Disassembling (create)" );

Set ( "#Warehouse", env.Warehouse );
Put ( "#Set", env.Set );
	
With ( form );

Set ( "#Quantity", env.Assembling );

// *************************
// Items Selection
// *************************

Click ( "#ItemsSelectItems" );

selectionForm = With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;	
if ( Fetch ( "#Filter" ) <> "None" ) then
	Pick ( "#Filter", "None" );
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

table = Activate ( "#Items" );
Call ( "Table.Clear", table );

Call ( "Table.AddEscape", table );

rowNumber = 0;
for each row in env.Items do
	Click ( "#ItemsAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
	rowNumber = rowNumber + 1;
	if ( rowNumber = 1 ) then
		Set ( "#ItemsCostRate", 40, table );
	else
		Set ( "#ItemsCostRate", 60, table );
	endif;
enddo;
Call ( "Table.CopyEscapeDelete", table );

Click ( "#FormPost" );
Call ( "Common.CheckCopying", Meta.Documents.Disassembling );

// ******************************************
// Test Shortage for CostOnline & CostOffline
// ******************************************

// CostOffline
Call ( "Catalogs.UserSettings.CostOnline", false );
Set ( "#Quantity", env.Overlimit );
Click ( "#FormPost" );
error = "Not enough " + ( env.overlimit - env.assembling ) + " * listed " + env.assembling;
Call ( "Common.CheckPostingError", error );

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );
Click ( "#FormPost" );
Call ( "Common.CheckPostingError", error );

Set ( "#Quantity", env.assembling );
Click ( "#FormPost" );

// ***********************************
// Test Logic for CostOnline & CostOffline
// ***********************************

// CostOffline
Call ( "Catalogs.UserSettings.CostOnline", false );
Click ( "#FormPost" );
Run ( "CostOffline" );

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );
Click ( "#FormPost" );
Run ( "Logic" );
Run ( "PrintForm" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "#2719D815" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Date", CurrentDate () );
	p.Insert ( "Warehouse", "_Assembling Warehouse " + id );
	p.Insert ( "Expenses", "_Assembling " + id );
	p.Insert ( "Account", "8111" );
	p.Insert ( "Set", "_Set " + id );
	p.Insert ( "Assembling", 25 );
	p.Insert ( "Overlimit", 30 );
	
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
	if ( Call ( "Common.DataCreated", id ) ) then
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
	
	// ***********************************
	// Create Assembling
	// ***********************************

	Call ( "Common.OpenList", Meta.Documents.Assembling );
	Click ( "#FormCreate" );
	form = With ( "Assembling (create)" );

	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Set", env.Set );
		
	With ( form );

	Set ( "#Quantity", Env.Assembling );

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
	Click ( "#FormPost" );

	Call ( "Common.StampData", id );

EndProcedure
