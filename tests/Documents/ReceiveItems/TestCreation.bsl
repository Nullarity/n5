// Description:
// Creates & Post document Receive Items
//
// Conditions:
// Command interface shoud be visible

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2619B731" );
env = getEnv ( id );
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.ReceiveItems );

form = With ( "Receive Items*" );
Click ( "Create", form.GetCommandBar () );

documentForm = With ( "Receive Items (create)" );

Call ( "Common.CheckCurrency", documentForm );

//
// Fill header
//
Put ( "#Warehouse", "Main" );
Put ( "#Account", "8111" );
With ( documentForm );
Put ( "#Dim1", Env.Expense );
//
// Add Items
//
// *************************
// Items Selection
// *************************

Click ( "#ItemsSelectItems" );

selectionForm = With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;	

Pick ( "#Filter", "None" );

table = Get ( "#ItemsList" );

for i = 1 to 2 do
	With ( selectionForm );
	GoToRow ( table, "Item", env.Item );
	table.Choose ();
	With ( "Details" );
	Set ( "#Quantity", 10 );
	Set ( "#Price", 3 );
	Click ( "#FormOK" );
enddo;

With ( selectionForm );
Click ( "#FormOK" );

With ( documentForm );
table = Activate ( "#GroupItems / #Items" );

Call ( "Table.Clear", table );
Call ( "Table.AddEscape", table );

Click ( "Command bar / Add", table );
Set ( "Item", Env.Item, table );
Set ( "Units", 10, table );
Set ( "Price", 3, table );
table.EndEditRow ();
Click ( "Command bar / Copy", table );
table.EndEditRow ();
//
// Post
//
Click ( "Post" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Receive Items*" );

CheckTemplate ( "TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Expense", "_Expense " + ID );
	p.Insert ( "Item", "_Item " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Expense
	// *************************
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// *************************
	// Create Item
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure

