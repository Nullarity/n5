// Test writing record to info register "Producer price"
//
// 1. Creating env
// 2. Creating and Posting doc
// 3. testing movments

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A4C9DAD" );
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
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Expense Report*" );
Call ( "Common.CheckLogic", "#TabDoc" );

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
		p.Social = true;
		Call ( "Catalogs.Items.Create", p );
	enddo;

	// *************************
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	Call ( "Common.StampData", id );
	
EndProcedure
