
// CAD Rate = 0.8
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2871EE14" );
env = getEnv ( " " + id );
createEnv ( env );

// *************************
// Create ExpenseReport
// *************************

Call ( "Catalogs.UserSettings.CostOnline", true );

p = Call ( "Documents.ExpenseReport.Create.Params" );
FillPropertyValues ( p, Env );
p.TaxGroup = "California";
Call ( "Documents.ExpenseReport.Create", p );

form = With ( "Expense Report*" );
Call ( "Common.CheckCurrency", form );
Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "Expense Report (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

Run ( "Logic" );

With ( form );
Click ( "#PaymentsCreate" );
paymentForm = With ();
Put ( "#Vendor", env.Vendor );
if ( Call ( "Common.AppIsCont" ) ) then
	Put ( "#Currency", "USD" );
	Put ( "#Rate", "15" );
	Put ( "#ContractRate", "10" );
	Put ( "#Amount", "5000" );
else
	Put ( "#Currency", "USD" );
	Put ( "#ContractRate", "0.8" );
	Put ( "#Amount", "50000" );
endif;
//Stop ( "Vendor: " + Fetch ( "#Vendor" ) + "Amount: " + Fetch ( "#Amount" ) + "; ContractAmount: " + Fetch ( "#ContractAmount" ) );

Click ( "#FormPost" );
checkerrors();
Run ( "LogicPayments" );
With ( paymentForm );
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Warehouse", "_Warehouse: " + ID );
	p.Insert ( "Employee", "_Employee: " + ID );
	p.Insert ( "Expense", "_Expense: " + ID );
	p.Insert ( "Department", "_Department: " + ID );
	p.Insert ( "Items", getItems ( ID ) );
	p.Insert ( "Services", getServices ( ID, p.Expense, p.Department ) );
	p.Insert ( "Services2", getServices ( ID, p.Expense, p.Department, 2 ) );
	p.Insert ( "Vendor", "_Vendor: " + ID );
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
	cont = Call ( "Common.AppIsCont" );
	if ( cont ) then
		p.Account = "7142";
	else
		p.Account = "60300";
	endif;
	p.Dim2 = Env.Department;
	p.Dim1 = Env.Expense;
	p.Amount = 100;
	rows.Add ( p );
	p = Call ( "Documents.ExpenseReport.Create.AccountsRow" );
	if ( cont ) then
		p.Account = "7141";
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
	With ( "Vendor Invoice #*" );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#Rate", "10" );
	else
	    Put ( "#Rate", "0.8" );
	endif;
	Click ( "#FormPostAndClose" );
	
	p.Services = Env.Services2;
	Call ( "Documents.VendorInvoice.Buy", p );
	With ( "Vendor Invoice #*" );
	if ( Call ( "Common.AppIsCont" ) ) then
		Put ( "#Rate", "10" );
	else
	    Put ( "#Rate", "0.8" );
	endif;    
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );
	
EndProcedure
