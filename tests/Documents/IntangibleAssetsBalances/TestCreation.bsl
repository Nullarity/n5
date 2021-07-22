Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28495CEC" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Click ( "#ListContextMenuChange" );
With ( "Intangible Assets Balances*" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Intangible Assets Balances *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Asset", "Intangible Asset: " + ID );
	p.Insert ( "Department", "Department: " + ID );
	p.Insert ( "Employee", "Responsible: " + ID );
	p.Insert ( "Expenses", "Expenses: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Asset
	// *************************
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.Asset;
	Call ( "Catalogs.IntangibleAssets.Create", p );
	
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
	// Create Expenses
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expenses );
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Description = Env.Expenses;
	p.Expense = Env.Expenses;
	p.Account = "8111";
	Call ( "Catalogs.ExpenseMethods.Create", p );
	
	// *************************
	// Create Intangible Assets Balances
	// *************************
	
	Commando ( "e1cib/list/DocumentJournal.Balances" );
	With ( "Opening Balances" );
	Click ( "#FormCreateByParameterIntangibleAssetsBalances" );
	
	form = With ( "Intangible Assets Balances (cr*" );
	Put ( "#Department", Env.Department );
	Put ( "#Employee", Env.Employee );
	Put ( "#Memo", id );
	Click ( "#ItemsAdd" );
	With ( "Intangible Asset" );
	Put ( "#IntangibleAsset", Env.Asset );
	Put ( "#UsefulLife", "60" );
	Put ( "#InitialCost", "100000" );
	Put ( "#Depreciation", "10000" );
	Put ( "#Expenses", Env.Expenses );
	Click ( "#Charge" );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );	
	
	RegisterEnvironment ( id );

EndProcedure
