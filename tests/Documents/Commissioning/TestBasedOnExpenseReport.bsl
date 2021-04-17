Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
Put ( "#EmployeeFilter", env.Employee );
Click ( "#FormDocumentCommissioningCreateBasedOn" );

form = With ( "Commissioning (create)" );
Put ( "#Warehouse", env.Warehouse );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Activate ( "#Items" );
Click ( "#ItemsEdit" );
With ( "Fixed Asset" );
Put ( "#Quantity", 10 );
Put ( "#FixedAsset", env.AssetNotPosted );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Commissioning #*" );
Call ( "Common.CheckLogic", "#TabDoc" );
With ( form );
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = " " + Call ( "Common.ScenarioID", "2864EEAD" ) + "#";
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "FixedAssets", getAssets ( "_Asset", p ) );
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
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
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
	// Create FixedAssets
	// *************************
	for each row in Env.FixedAssets do
		p = Call ( "Catalogs.FixedAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.FixedAssets.Create", p );
	enddo;
	
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = Env.AssetNotPosted;
	Call ( "Catalogs.FixedAssets.Create", p );		

	// *************************
	// Create ExpenseReport
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	p.TaxGroup = "California";
	Call ( "Documents.ExpenseReport.Create", p );
	form = With ( "Expense Report*" );
 	
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );
	
EndProcedure

