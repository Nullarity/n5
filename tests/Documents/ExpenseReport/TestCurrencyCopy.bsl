// CAD Rate = 10
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/ChartOfAccounts.General" );
With ( "Chart Of Accounts" );
find = Call ( "Common.Find.Params" );
find.Where = "Code";
find.What = "2262";
Call ( "Common.Find", find );
Click ( "#FormChange" );
form = With ( "12800*" );
if ( Fetch ( "#Currency" ) = "No" ) then
	Click ( "#Currency" );
	Click ( "#FormWriteAndClose" );
else
	Close ( form );
endif;	

// *************************
// Create ExpenseReport
// *************************

Call ( "Catalogs.UserSettings.CostOnline", true );

p = Call ( "Documents.ExpenseReport.Create.Params" );
FillPropertyValues ( p, Env );
p.TaxGroup = "California";
Call ( "Documents.ExpenseReport.Create", p );

form = With ( "Expense Report*" );
Put ( "#Currency", "CAD" );
Put ( "#Rate", "10" );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Expense Report*" );
Call ( "Common.CheckLogic", "#TabDoc" );

MainWindow.ExecuteCommand ( "e1cib/list/ChartOfAccounts.General" );
With ( "Chart Of Accounts" );
find = Call ( "Common.Find.Params" );
find.Where = "Code";
find.What = "2262";
Call ( "Common.Find", find );
Click ( "#FormChange" );
With ( "12800*" );
Click ( "#Currency" );
Click ( "#FormWriteAndClose" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "2863C60F" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Services", getServices ( id, p.Expense, p.Department ) );
	p.Insert ( "IntangibleAssets", getAssets ( "_IntangibleAsset", p ) );
	p.Insert ( "FixedAssets", getAssets ( "_Asset", p ) );
	p.Insert ( "Accounts", getAccounts ( p ) );
	return p;

EndFunction

Function getItems ( ID )

	rows = new Array ();
	rows.Add ( rowItem ( "_Item1: " + ID, 10, 100 ) );
	return rows;

EndFunction

Function rowItem ( Item, Quantity, Price, CountPackages = false )

	row = Call ( "Documents.ExpenseReport.Create.ItemsRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	row.Insert ( "CountPackages", CountPackages );
	return row;

EndFunction

Function getServices ( ID, Expense, Department, Multiplicant = 1 )

	rows = new Array ();
	rows.Add ( rowServices ( "_Service1: " + ID, 10, 100 * Multiplicant, Expense, Department ) );
	return rows;

EndFunction

Function rowServices ( Item, Quantity, Price, Expense, Department )

	row = Call ( "Documents.ExpenseReport.Create.ServicesRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	row.Account = "8111";
	row.Expense = Expense;
	row.Department = Department;
	return row;

EndFunction

Function getAssets ( AssetName, Env )

	id = Env.ID;
	rows = new Array ();
	p = Call ( "Documents.ExpenseReport.Create.AssetsRow" );
	p.Department = Env.Department;
	p.Item = AssetName +"1: " + id;
	p.Employee = Env.Employee;
	p.Amount = 10000;
	rows.Add ( p );
	return rows;

EndFunction

Function getAccounts ( Env )

	rows = new Array ();                                            
	p = Call ( "Documents.ExpenseReport.Create.AccountsRow" );
	p.Account = "60300";
	p.Dim2 = Env.Department;
	p.Dim1 = Env.Expense;
	p.Amount = 100;
	rows.Add ( p );
	return rows;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	Run ( "ExpenseReportAccount" );
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
		Call ( "Catalogs.Items.Create", p );
	enddo;

	for each row in Env.Services do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.Service = true;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// *************************
	// Create Warehouse
	// *************************
	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );

	// *************************
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	// *************************
	// Create Expense
	// *************************
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// *************************
	// Create Department
	// *************************
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

	// *************************
	// Create IntangibleAsset
	// *************************
	for each row in Env.IntangibleAssets do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;	
	
	// *************************
	// Create FixedAsset
	// *************************
	for each row in Env.FixedAssets do
		p = Call ( "Catalogs.FixedAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.FixedAssets.Create", p );
	enddo;		

	RegisterEnvironment ( id );
	
EndProcedure
