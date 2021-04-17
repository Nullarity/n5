//!!!Setting Expense Report Debt must be 5321
//
// Test closing employees debts
//
// 1. Creating ExpenseReport
// 2. Creating ClosingEmployees
// 3. Check movements

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2875F243" );
env = getEnv ( " " + id );
createEnv ( env );

// *************************
// Create ClosingEmployees
// *************************

Commando ( "e1cib/list/Document.ClosingEmployees" );
list = With ( "Closings Employees Debts" );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.ID;
Call ( "Common.Find", p );

With ( list );

count = Call ( "Table.Count", Get ( "#List" ) );
if ( count = 0 ) then
	Commando ( "e1cib/data/Document.ClosingEmployees" );
	form = With ();	
	Put ( "#Memo", id );	
else
	Click ( "#FormChange" );
	form = With ();
	// Unpost if it is already posted
	postedLabel = Get ( "#FormUndoPosting" );
	if ( postedLabel.CurrentVisible () ) then
		Click ( "#FormUndoPosting" );
	endif;
endif;

Close ( list );                                    

Put ( "#Date", "01/31/2018" );

Click ( "#Fill" );

With ( "Closing Employees Debts: Setup Filters" );
table = Get ( "#UserSettings" );
//GotoRow ( table, "Setting", "Employee Account" );
//Put ( "#UserSettingsValue", "22611", table );

GotoRow ( table, "Setting", "Employee" );
Put ( "#UserSettingsValue", env.Employee, table );

Click ( "#FormFill" );
Pause ( __.Performance * 7 );

With ( form );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Closing Employees Debts*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Items", getItems ( "_Item1: " + ID, ID ) );
	p.Insert ( "Employee", "Employee:" + ID );
	p.Insert ( "Department", "Department" + ID );
	p.Insert ( "Warehouse", "Warehouse" + ID );
	return p;

EndFunction

Function getItems ( Item, ID )

	rows = new Array ();
	rows.Add ( rowItem ( Item, 10, 100 ) );
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

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
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
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create ExpenseReport
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	p.Date = "01/01/2018";
	Call ( "Documents.ExpenseReport.Create", p );

	form = With ( "Expense Report*" );
	Click ( "#FormPost" );


	Call ( "Common.StampData", id );
	
EndProcedure

