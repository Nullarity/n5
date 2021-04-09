
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/data/Document.ReceiveItems" );
form = With ( "Receive Items (cr*" );
Set ( "#Warehouse", env.Warehouse );
Set ( "#Account", env.Account );
Next ();

for i = 0 to 1 do
	if ( i = 0 ) then
		table = Activate ( "#FixedAssets" );
		Click ( "#FixedAssetsAdd", table );
		With ( "Fixed Asset" );
		Set ( "#Item", env.FixedAsset );
	else
		table = Activate ( "#IntangibleAssets" );
		Click ( "#IntangibleAssetsAdd", table );
		With ( "Intangible Asset" );
		Set ( "#Item", env.IntangibleAsset );
	endif;

	Set ( "#Department", "Administration" );
	Click ( "#Charge" );
	Clear ( "#Starting" );
	Click ( "#FormOK" );
	With ( form );
	IgnoreErrors = true;
	Click ( "#FormPost" );
	Call ( "Common.FillCheckError", "Calculation *" );
	Call ( "Table.Clear", table );
	Click ( "#FormWrite" );
	IgnoreErrors = false;
enddo;

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618114877#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Warehouse", "Main" );
	env.Insert ( "Account", "8111" );
	env.Insert ( "FixedAsset", "_Asset " + id );
	env.Insert ( "IntangibleAsset", "_Asset " + id );
	return env;

EndFunction

Procedure createEnv ( env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;

	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = env.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = env.IntangibleAsset;
	Call ( "Catalogs.IntangibleAssets.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
