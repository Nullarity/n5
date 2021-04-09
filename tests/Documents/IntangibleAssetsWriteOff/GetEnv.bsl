env = getEnv ( _ );
createEnv ( env );

return env;

// *************************
// Procedures
// *************************

Function getEnv ( ID )

 	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "Warehouse", "_Warehouse: " + ID );
	if ( Call ( "Common.AppIsCont" ) ) then
		env.Insert ( "ReceiveAccount", "6118" );
		env.Insert ( "ExpenseAccount", "7141" );
	else
		env.Insert ( "ReceiveAccount", "70100" );
		env.Insert ( "ExpenseAccount", "8111" );
	endif;
	env.Insert ( "Department", "_ Department " + ID );
	env.Insert ( "Responsible", "Employee " + ID );
	env.Insert ( "Expense", "_Expense " + ID );
	env.Insert ( "Expenses", "_Expenses " + ID );
	
	items = new Array ();
	items.Add ( newItem ( "_Intangible asset " + ID, 1, 150 ) );
	items.Add ( newItem ( "_Intangible asset, pkg " + ID, 1, 250 ) );
	env.Insert ( "Items", items );
	return env;

EndFunction

Function newItem ( Name, Quantity, Amount )

	p = new Structure ( "Name, Quantity, Amount" );
	p.Name = Name;
	p.Quantity = Quantity;
	p.Amount = Amount;
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************
	// Create Department
	// ***********************

	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// ***********************
	// Create Expense
	// ***********************

	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// ***********************
	// Create Expenses
	// ***********************

	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Description = Env.Expenses;
	p.Expense = Env.Expense;
	p.Account = Env.ExpenseAccount;
	Call ( "Catalogs.ExpenseMethods.Create", p );
	
	// ***********************
	// Create Warehouse
	// ***********************

	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );
	
	// ***********************
	// Create Employee
	// ***********************

	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );

	// ***********************
	// Create Assets
	// ***********************
	
	for each item in Env.Items do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = item.Name;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	// ***********************
	// Receice Items
	// ***********************

	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Account = Env.ExpenseAccount;
	p.Warehouse = Env.Warehouse;
	p.Date = Env.Date - 86400;
	assets = p.IntangibleAssets;
	p.Expenses = Env.Expenses;
	for each item in Env.Items do
		row = Call ( "Documents.ReceiveItems.Receive.Asset" );
		row.Asset = item.Name;
		row.Amount = item.Amount;
		row.Department = Env.Department;
		row.Responsible = Env.Responsible;
		assets.Add ( row );
	enddo;
	Call ( "Documents.ReceiveItems.Receive", p );

	Call ( "Common.StampData", id );

EndProcedure