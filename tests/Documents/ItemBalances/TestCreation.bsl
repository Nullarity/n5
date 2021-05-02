// Create a new Item Balances
// Add one position
// Post the document

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2863CC00" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/DocumentJournal.Balances" );
With ();
if ( Date(Fetch ( "#BalanceDate" )) = Date(1, 1, 1) ) then
	Set("#BalanceDate", Format(CurrentDate(), "DLF=D"));
endif;

Click ( "#FormCreateByParameterItemBalances" );
With ();

Put ( "#Account", "2171" );
Put ( "#Warehouse", "Main" );
table = Get ( "#Items" );
Click ( "#ItemsAdd" );
Put ( "#ItemsItem", env.Item, table );
Put ( "#ItemsQuantityPkg", 100, table );
Put ( "#ItemsAmount", 1500, table );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records:*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item: " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	Call ( "Common.StampData", id );
	
EndProcedure
