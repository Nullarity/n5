Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
Put ( "#EmployeeFilter", env.Employee );
Click ( "#FormDocumentIntangibleAssetsCommissioningCreateBasedOn" );

form = With ( "Intangible Assets Commissioning (create)" );
Put ( "#Warehouse", env.Warehouse );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Activate ( "#Items" );
Click ( "#ItemsEdit" );
With ( "Intangible Asset" );
Put ( "#Quantity", 10 );
Put ( "#IntangibleAsset", env.AssetNotPosted );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Intangible Assets Commissioning #*" );
Call ( "Common.CheckLogic", "#TabDoc" );
With ( form );
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "2863C838" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "IntangibleAssets", getAssets ( "_Intangible Asset", p ) );
	p.Insert ( "AssetNotPosted", "_AssetNotPosted: " + id );
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
	row.Account = "15100";
	row.Insert ( "CountPackages", CountPackages );
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
	p = Call ( "Documents.ExpenseReport.Create.AssetsRow" );
	p.Department = Env.Department;
	p.Item = AssetName +"2: " + id;
	p.Employee = Env.Employee;
	p.Amount = 20000;
	rows.Add ( p );
	return rows;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	Call ( "Documents.ExpenseReport.ExpenseReportAccount" );
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
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
	// Create IntangibleAssets
	// *************************
	for each row in Env.IntangibleAssets do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.AssetNotPosted;
	Call ( "Catalogs.IntangibleAssets.Create", p );		

	// *************************
	// Create ExpenseReport
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	p.TaxGroup = "California";
	Call ( "Documents.ExpenseReport.Create", p );
	form = With ( "Expense Report*" );
 	
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure

