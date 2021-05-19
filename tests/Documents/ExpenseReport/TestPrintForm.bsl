// CAD Rate = 10
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
Put ( "#EmployeeFilter", env.Employee );
if ( Call ( "Common.AppIsCont" ) ) then
	Run ( "TestPrintCont" );
else
	Click ( "#FormDocumentExpenseReportExpenseReport" );
	With ( "Expense Report: Print" );
	Call ( "Common.CheckLogic", "#TabDoc" );
endif;


// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "2D1FCB93" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Services", getServices ( id, p.Expense, p.Department ) );
	p.Insert ( "Services2", getServices ( id, p.Expense, p.Department, 2 ) );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "IntangibleAssets", getAssets ( "_IntangibleAsset", p ) );
	p.Insert ( "FixedAssets", getAssets ( "_Asset", p ) );
	p.Insert ( "Accounts", getAccounts ( p ) );
	return p;

EndFunction

Function getItems ( ID )

	rows = new Array ();
	rows.Add ( rowItem ( "_Item1: " + ID, 10, 100 ) );
	rows.Add ( rowItem ( "_Item2, pkg: " + ID, 10, 100, true ) );
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
	rows.Add ( rowServices ( "_Service2: " + ID, 10, 100 * Multiplicant, Expense, Department ) );
	return rows;

EndFunction

Function rowServices ( Item, Quantity, Price, Expense, Department )

	row = Call ( "Documents.ExpenseReport.Create.ServicesRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	if ( Call ( "Common.AppIsCont" ) ) then
		row.Account = "7141";
	else
		row.Account = "8111";
	endif;
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
	p = Call ( "Documents.ExpenseReport.Create.AssetsRow" );
	p.Department = Env.Department;
	p.Item = AssetName +"2: " + id;
	p.Employee = Env.Employee;
	p.Amount = 20000;
	rows.Add ( p );
	return rows;

EndFunction

Function getAccounts ( Env )

	rows = new Array ();                                            
	p = Call ( "Documents.ExpenseReport.Create.AccountsRow" );
	if ( Call ( "Common.AppIsCont" ) ) then
		p.Account = "7141";
	else
		p.Account = "60300";
	endif;
	
	p.Dim2 = Env.Department;
	p.Dim1 = Env.Expense;
	p.Amount = 100;
	rows.Add ( p );
	p = Call ( "Documents.ExpenseReport.Create.AccountsRow" );
	if ( Call ( "Common.AppIsCont" ) ) then
		p.Account = "7142";
	else
		p.Account = "8111";
	endif;
	p.Dim2 = Env.Department;
	p.Dim1 = Env.Expense;
	p.Amount = 200;
	rows.Add ( p );
	return rows;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	// Create Vendor
	// *************************
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Organization = Env.Vendor;
	p.Currency = "CAD";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
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

	// *************************
	// Create Vendor Invoice
	// *************************
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Vendor = Env.Vendor;
	p.Warehouse = Env.Warehouse;
	p.Currency = "CAD";
	p.ID = id;
	p.Services = Env.Services;
	p.Expenses = Env.Expense;
	Call ( "Documents.VendorInvoice.Buy", p );
	Close ( With ( "Vendor Invoice #*" ) );

	p.Services = Env.Services2;
	Call ( "Documents.VendorInvoice.Buy", p );
	Close ( With ( "Vendor Invoice #*" ) );
	
	// *************************
	// Create ExpenseReport
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	p.TaxGroup = "California";
	Call ( "Documents.ExpenseReport.Create", p );
	form = With ( "Expense Report*" );
	
	Click ( "#JustSave" );
	Click ( "#PaymentsCreate" );

//	With ( DialogsTitle );
//	Click ( "Yes" );

	paymentForm = With ( "Vendor Payment (create)" );
	Put ( "#Vendor", env.Vendor );
	Put ( "#Amount", 50000 );
	Click ( "#FormPostAndClose" );

	With ( form );
	Click ( "#PaymentsCreate" );
	paymentForm = With ( "Vendor Payment (create)" );
	Put ( "#Vendor", env.Vendor );
	Put ( "#Amount", 100000 );
	Click ( "#FormPostAndClose" );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );
	
EndProcedure
