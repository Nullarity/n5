Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6EA39D" );

env = getEnv ( id );
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.ID;
Call ( "Common.Find", p );

Click ( "#FormDataProcessorExpenseReportExpenseReport" );
With ( "Expense Report: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Services", getServices ( id, p.Expense, p.Department ) );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "Accounts", getAccounts ( p ) );
	return p;

EndFunction

Function getItems ( ID )

	row = Call ( "Documents.ExpenseReport.Create.ItemsRow" );
	row.Item = "_Item " + ID;
	row.Quantity = 1;
	row.Price = 100;
	row.Date = Format ( Date ( 2017, 1, 1 ), "DLF=D" );
	row.Number = "0001";
	rows = new Array ();
	rows.Add ( row );
	return rows;

EndFunction

Function getServices ( ID, Expense, Department )

	row = Call ( "Documents.ExpenseReport.Create.ServicesRow" );
	row.Item = "_Service " + ID;
	row.Quantity = 1;
	row.Price = 150;
	row.Account = "7141";
	row.Expense = Expense;
	row.Department = Department;
	row.Date = Format ( Date ( 2017, 1, 2 ), "DLF=D" );
	row.Number = "0002";
	rows = new Array ();
	rows.Add ( row );
	return rows;

EndFunction

Function getAccounts ( Env )

	rows = new Array ();                                            
	p = Call ( "Documents.ExpenseReport.Create.AccountsRow" );
	p.Account = "7142";
	p.Dim2 = Env.Department;
	p.Dim1 = Env.Expense;
	p.Amount = 50;
	p.Date = Format ( Date ( 2017, 1, 3 ), "DLF=D" );
	p.Number = "0003";
	p.Content = "Testing Content";
	rows.Add ( p );
	return rows;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Set Default Employee Account
	// *************************
	
	Call ( "Documents.ExpenseReport.ExpenseReportAccount", "22611" );
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
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
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Cash expense ( Operation )
	// *************************
	
	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Cash Expense";
	operation = "Cash Expense" + id;
	p.Description = operation;
	p.Simple = true;
	p.AccountDr = "22611";
	p.AccountCr = "2411";
	Call ( "Catalogs.Operations.Create", p );

	// *************************
	// Create Entry ( giving money ) for balance
	// *************************
	
	cashExpense ( operation, BegOfYear ( CurrentDate () ), Env.Employee, "500" );
	
	// *************************
	// Create ExpenseReport for Balance
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	p.TaxGroup = "California";
	p.Employee = Env.Employee;
	
	p.Date = Format ( ( BegOfYear ( CurrentDate () ) + 86400 ), "DLF=DT" );
	Call ( "Documents.ExpenseReport.Create", p );

	form = With ( "Expense Report*" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Entry ( giving money )
	// *************************
	cashExpense ( operation, CurrentDate (), Env.Employee, "1000" );
	cashExpense ( operation, CurrentDate (), Env.Employee, "500" );
	
	// *************************
	// Create Vendor Invoice
	// *************************
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Vendor = Env.Vendor;
	p.Warehouse = Env.Warehouse;
	p.ID = id;
	p.Services = Env.Services;
	p.Expenses = Env.Expense;
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
	Click ( "#FormPost" );
	
	Click ( "#PaymentsCreate" );
	paymentForm = With ( "Vendor Payment (create)" );
	Put ( "#Vendor", env.Vendor );
	Put ( "#Amount", 150 );
	Click ( "#FormPost" );
	With ( paymentForm );

	RegisterEnvironment ( id );
	
EndProcedure

Procedure cashExpense ( Operation, Date, Employee, Amount )
	
	Commando ( "e1cib/data/Document.Entry" );
	With ( "Entry (cr*" );
	Put ( "#Operation", operation );
	Put ( "#Date", Format ( Date, "DLF=DT" ) );
	Put ( "#DimDr1", Employee );
	Put ( "#RecordAmount", Amount );
	Click ( "#FormPostAndClose" );

EndProcedure

