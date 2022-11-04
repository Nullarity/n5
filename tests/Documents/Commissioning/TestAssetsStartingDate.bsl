﻿
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( Env );

MainWindow.ExecuteCommand ( "e1cib/data/Document.Commissioning" );
form = With ( "Commissioning (cr*" );
                         
table = Activate ( "#Items" );
Close ( "Fixed Asset" );

Put ( "#Warehouse", env.Warehouse );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Responsible );

Click ( "#ItemsAdd" );
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
CloseAll ();
IgnoreErrors = false;

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "B111" );
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

	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = env.Item;
	Call ( "Catalogs.Items.Create", p );

	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = env.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );

EndProcedure
