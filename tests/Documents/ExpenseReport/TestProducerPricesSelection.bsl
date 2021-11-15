// Test writing record to info register "Producer price"
//
// 1. Creating env
// 2. Creating and Posting doc
// 3. testing movments

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "267D392A" );
env = getEnv ( " " + id );
createEnv ( env );

// *************************
// Create ExpenseReport
// *************************

p = Call ( "Documents.ExpenseReport.Create.Params" );
FillPropertyValues ( p, Env );
p.TaxGroup = "California";
Call ( "Documents.ExpenseReport.Create", p );

form = With ( "Expense Report*" );

Activate ( "#ItemsTable" );
Click ( "#ItemsTableContextMenuDelete" );

// Test selection
Click ( "#ItemsSelectItems" );
selection = With ( "Items Selection" );

if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;

Pick ( "#Filter", "None" );

// *************************************
// Enable prices
// *************************************

flag = Fetch ( "#ShowPrices" );
if ( flag = "No" ) then
	Click ( "#ShowPrices" );
endif;

// *************************************
// Search Item
// *************************************

p = Call ( "Common.Find.Params" );
p.Where = "Item";
p.What = env.Items [ 0 ].Item;
p.Button = "#ItemsListContextMenuFind";
Call ( "Common.Find", p );

table = Get ( "#ItemsList" );
table.Choose ();

details = With ( "Details" );
Put ( "#QuantityPkg", 2 );
Put ( "#ProducerPrice", 200 );

Click ( "#FormOK" );

With ( selection );
Click ( "#FormOK" );

With ( form );
table = Get ( "#ItemsTable" );
Check ( "#ItemsProducerPrice", 200, table );


// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Employee", "_Employee: " + ID );
	p.Insert ( "Items", getItems ( ID ) );
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
	row.Social = true;
	row.ProducerPrice = Price + 50;
	row.Insert ( "CountPackages", CountPackages );
	return row;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Items
	// *************************
	
	for each row in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = row.Item;
		p.CountPackages = row.CountPackages;
		p.Social = true;
		Call ( "Catalogs.Items.Create", p );
	enddo;

	// *************************
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );
	
EndProcedure
