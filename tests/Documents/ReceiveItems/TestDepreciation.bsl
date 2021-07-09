StandardProcessing = false;

Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// *************************
// Create Receive Items
// *************************
p = Call ( "Documents.ReceiveItems.Create.Params" );
p.Warehouse = Env.Warehouse;
p.Account = "8111";
p.ID = Env.ID;
p.FixedAssets = Env.FixedAssets;
Call ( "Documents.ReceiveItems.Create", p );

With ( "Receive Items*" );
Click ( "#FormPost" );

if ( FindMessages ( "Expenses not filled" ).Count () = 0 ) then
	Stop ( " dialog box must be shown" );
endif;


// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", " 256182F6#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Department", "_Department" + id );
	p.Insert ( "Warehouse", "_Warehouse" + id );
	p.Insert ( "Expense", "_Expense" + id );
	p.Insert ( "Employee", "_Employee" + id );
	p.Insert ( "Expenses", "_Expenses Method" + id );
	p.Insert ( "FixedAssets", assets ( p, "_Fixed Asset" ) );
	return p;

EndFunction

Function assets ( Env, Asset )

	id = Env.ID;
	assets = new Array ();
	assets.Add ( assetRow ( Env, Asset, "Linear", true ) );
	assets.Add ( assetRow ( Env, Asset, "Cumulative", false ) );
	return assets;

EndFunction

Function assetRow ( Env, Asset, Mehtod, SetExpenses )

	p = Call ( "Documents.ReceiveItems.Create.AssetRow" );
	p.Item = Asset + " " + Mehtod + Env.ID;
	p.Amount = 10000;
	p.Department = Env.Department;
	p.Employee = Env.Employee;
	p.Method = Mehtod;
	p.UsefulLife = 3;
	if ( SetExpenses ) then
		p.Expenses = Env.Expenses;
	endif;	
	p.LiquidationValue = 3000;
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
	
	RegisterEnvironment ( id );

EndProcedure
