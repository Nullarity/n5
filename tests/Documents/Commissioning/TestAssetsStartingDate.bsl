
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( Env );

MainWindow.ExecuteCommand ( "e1cib/data/Document.Commissioning" );
form = With ( "Commissioning (cr*" );

table = Activate ( "#Items" );
Close ( "Fixed Asset" );

Set ( "#Warehouse", env.Warehouse );
Set ( "#Department", env.Department );
Set ( "#Employee", env.Responsible );

table = Activate ( "#Items" );
Click ( "#ItemsEdit" );
With ( "Fixed Asset" );
Set ( "#Item", env.Item );
Set ( "#QuantityPkg", "1" );
Set ( "#FixedAsset", env.FixedAsset );

Click ( "#Charge" );
Clear ( "#Starting" );
Click ( "#FormOK" );
With ( form );
IgnoreErrors = true;
Click ( "#FormPost" );
Call ( "Common.FillCheckError", "Calculation *" );
Call ( "Table.Clear", table );
Click ( "#JustSave" );
IgnoreErrors = false;

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "253FF541" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Warehouse", "Main" );
	env.Insert ( "Department", "Administration" );
	env.Insert ( "Responsible", "Responsible " + id );
	env.Insert ( "Account", "8111" );
	env.Insert ( "Item", "_Item " + id + "#" );
	env.Insert ( "FixedAsset", "_Asset " + id + "#" );
	return env;

EndFunction

Procedure createEnv ( env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	Call ( "Catalogs.Items.CreateIfNew", env.Item );

	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = env.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );

EndProcedure
