﻿// Test calculation Extra Charge
//
// 1. Creating VendorInvoice with producer price
// 2. Creating invoice
// 3. testing calculaiton extracharge = ( price - producer price ) / producer price * 100

Call ( "Common.Init" );
CloseAll ();
id = Call ( "Common.ScenarioID", "2B6A9FFC" );
env = getEnv ( " " + id );
createEnv ( env );

// *************************
// Create Invoice
// *************************

Commando ( "e1cib/data/Document.Invoice" );
form = With ( "Invoice (cr*" );

Put ( "#Customer", env.Customer );

// Items
table = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );

Put ( "#ItemsItem", env.Item, table );
Put ( "#ItemsQuantityPkg", 2, table );
Put ( "#ItemsPrice", 200, table );
Pick ( "#VATUse", "Excluded from Price" );
Check ( "#ItemsExtraCharge", 33.33, table );

Put ( "#Department", Env.Department );

Click ( "#JustSave" );

//Click ( "#FormReportRecordsShow" );
//With ( "Records: Invoice*" );
//Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "_Item1: " + ID );
	p.Insert ( "Items", getItems ( p.Item, ID ) );
	p.Insert ( "Employee", "Employee: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
	p.Insert ( "Department", "Department " + ID );
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
	row.Social = true;
	row.ProducerPrice = Price + 50;
	return row;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
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
	
	// *************************
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Customer" );
	Put ( "#Description", Env.Customer );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create ExpenseReport
	// *************************

	p = Call ( "Documents.ExpenseReport.Create.Params" );
	FillPropertyValues ( p, Env );
	Call ( "Documents.ExpenseReport.Create", p );

	form = With ( "Expense Report*" );
	Put ( "#Date", "01/01/2018" );
	Click ( "#FormPostAndClose" );


	RegisterEnvironment ( id );
	
EndProcedure
