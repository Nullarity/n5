Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// test november 2016 must be empty calculation
date = env.Date;
env.Date = env.LastDate;
Run ( "Calculate", env );

// test december 2016
env.Date = date;
Run ( "Calculate", env );

// test january 2017
env.Date = EndOfMonth ( AddMonth ( env.Date, 1 ) );
Run ( "Calculate", env );

// test february 2017
env.Date = EndOfMonth ( AddMonth ( env.Date, 1 ) );
Run ( "Calculate", env );

// *************************
// Procedures
// *************************

Procedure writeOffAssets ( Env )

	p = Call ( "Documents.AssetsWriteOff.WriteOffAllAssets.Params" );	
	p.Date = EndOfMonth ( Env.LastDate );
	p.ExceptAssets = Env.FixedAssets;
	Call ( "Documents.AssetsWriteOff.WriteOffAllAssets", p );
	p.ExceptAssets = Env.IntangibleAssets;
	Call ( "Documents.IntangibleAssetsWriteOff.WriteOffAllAssets", p );

EndProcedure

Function getEnv ()

	id = " " + Call ( "Common.ScenarioID", "2A4CAAC4" ) + "#";
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Department", "_Department" + id );
	p.Insert ( "Warehouse", "_Warehouse" + id );
	p.Insert ( "Employee", "_Employee" + id );
	p.Insert ( "Shedule", "_Shedule" + id );
	p.Insert ( "Expenses", "_Expenses Method" + id );
	p.Insert ( "Expense", "_Expense" + id );
	p.Insert ( "FixedAssets", assets ( p, "_Fixed Asset" ) );
	p.Insert ( "IntangibleAssets", intangibleAssets ( p, "_Intangible Asset" ) );
	date = Date ( 2016, 12, 1 );
	p.Insert ( "LastDate", BegOfMonth ( date ) - 1 );
	p.Insert ( "Date", date );
	return p;

EndFunction

Function assets ( Env, Asset )

	id = Env.ID;
	assets = new Array ();
	assets.Add ( assetRow ( Env, Asset, "Linear" ) );
	assets.Add ( assetRow ( Env, Asset, "Cumulative" ) );
	assets.Add ( assetRow ( Env, Asset, "Decreasing" ) );
	assets.Add ( assetRow ( Env, Asset + " Shedule", "Linear", true ) );
	return assets;

EndFunction

Function assetRow ( Env, Asset, Mehtod, SetShedule = false )

	p = Call ( "Documents.ReceiveItems.Create.AssetRow" );
	p.Item = Asset + " " + Mehtod + Env.ID;
	p.Amount = 10000;
	p.Department = Env.Department;
	p.Employee = Env.Employee;
	p.Method = Mehtod;
	p.UsefulLife = 3;
	p.Expenses = Env.Expenses;
	p.LiquidationValue = 3000;
	if ( SetShedule )
		and ( p.Method = "Linear" ) then
		p.Shedule = Env.Shedule;
		p.UsefulLife = 12;
	endif;	
	return p;

EndFunction

Function intangibleAssets ( Env, Asset )

	id = Env.ID;
	assets = new Array ();
	assets.Add ( assetRow ( Env, Asset, "Linear" ) );
	assets.Add ( assetRow ( Env, Asset, "Cumulative" ) );
	assets.Add ( assetRow ( Env, Asset, "Decreasing" ) );
	return assets;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Shedule
	// *************************
	p = Call ( "Catalogs.DepreciationSchedules.Create.Params" );
	p.Description = Env.Shedule;
	p.Rate1 = 100;
	p.Rate12 = 100;
	Call ( "Catalogs.DepreciationSchedules.Create", p );

	// *************************
	// Create Expense
	// *************************
	expense = Env.Expense;
	Call ( "Catalogs.Expenses.Create", expense );
	
	// *************************
	// Create Expenses
	// *************************
	
	p  = Call ( "Catalogs.ExpenseMethods.Create.Params" );	
	p.Description = Env.Expenses;
	p.Account = "8111";
	p.Expense = expense;
	Call ( "Catalogs.ExpenseMethods.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );	
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create FixedAssets
	// *************************
	for each row in Env.FixedAssets do
		p = Call ( "Catalogs.FixedAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.FixedAssets.Create", p );
	enddo;	
	
	// *************************
	// Create IntangibleAssets
	// *************************
	for each row in Env.IntangibleAssets do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	// *************************
	// Create Receive Items
	// *************************
	p = Call ( "Documents.ReceiveItems.Create.Params" );
	p.Date = Env.LastDate;
	p.Warehouse = Env.Warehouse;
	p.Account = "8111";
	p.ID = Env.ID;
	p.FixedAssets = Env.FixedAssets;
	p.IntangibleAssets = Env.IntangibleAssets;
	Call ( "Documents.ReceiveItems.Create", p );
	
	With ( "Receive Items*" );
	Click ( "#FormPost" );
	
	// test copy
	MainWindow.ExecuteCommand ( "e1cib/list/Document.AssetsCalculation" );
	With ( "Assets Calculations" );
	Click ( "#FormCreate" );
	With ( "Assets Calculation (create)" );
	Click ( "#FormWrite" );
	Click ( "#FormCopy" );
	copy = "Assets Calculation (create)";
	if ( not Waiting ( copy ) ) then
		Stop ( "The copy of document shoul be appeared" );
	endif;
	CloseAll ();	
	
	Call ( "Common.StampData", id );

EndProcedure
