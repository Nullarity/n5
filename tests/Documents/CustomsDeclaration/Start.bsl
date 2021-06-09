Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BD9DD64" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Customs Declaration
// *************************

MainWindow.ExecuteCommand ( "e1cib/data/Document.CustomsDeclaration" );
form = With ( "Customs Declaration (create)" );
Put ( "#Customs", Env.Customs );
Put ( "#VATAccount", "5344" );

table = Activate ( "#CustomGroups" );
Set ( "#CustomGroupsCustomsGroup", env.CustomsGroup, table );

Click ( "#ItemsAddFromInvoice" );
With ( "Vendor Invoices" );
p = Call ( "Common.Find.Params" );
p.Where = "Vendor";
p.What = env.Vendor;
Call ( "Common.Find", p );
Click ( "#FormChoose" );

With ( "Items*" );
Click ( "#FormSelect" );

With ( form );
Click ( "#ShowDetails" );
table = Activate ( "#Charges" );
search = new Map ();
search.Insert ( "Charge", "Таможенная пошлина, 020" );
table.GotoFirstRow ();
table.GotoRow ( search, RowGotoDirection.Down );
Activate ( "#ChargesCost", table );
Put ( "#ChargesCost", "Expense", table );
Put ( "#ChargesExpenseAccount", "7141", table );
Put ( "#ChargesDim1", env.Expense, table );
Put ( "#ChargesDim2", env.Department, table );

Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "Customs Declaration (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

Run ( "Logic" );
Run ( "LogicImport", env );
With ( form );

Click ( "#FormUndoPosting" );

// ***********************************
// Procedures
// ***********************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", "01/01/2019" );
	env.Insert ( "Warehouse", "Warehouse: " + ID );
	env.Insert ( "Expense", "Expense: " + ID );
	env.Insert ( "Department", "Department: " + ID );
	env.Insert ( "Vendor", "Vendor: " + ID );
	env.Insert ( "Customs", "Customs: " + ID );
	env.Insert ( "CustomsGroup", "CustomsGroup: " + ID );
	env.Insert ( "Item1", "Item1: " + ID );
	env.Insert ( "Item2", "Item2: " + ID );
	env.Insert ( "Rate", "15.1779" );
	env.Insert ( "Goods", getGoods ( Env ) );
	env.Insert ( "Payments", getPayments () );
	return env;

EndFunction

Function getGoods ( Env );

	goods = new Array ();
	
 	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
 	row.Item = Env.Item1;
	row.Quantity = "1";
	row.Price = "1000";
	goods.Add ( row );
	
	row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
	row.Item = Env.Item2;
	row.Quantity = "1";
	row.Price = "100";
	goods.Add ( row );
	
	return goods;

EndFunction

Function getPayments ();

	payments = new Array ();
	
 	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "Плата за таможенные процедуры, 010";
	row.Percent = 10;
	payments.Add ( row );
	
	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "Таможенная пошлина, 020";
	row.Percent = 5;
	payments.Add ( row );
	
	row = Call ( "Catalogs.CustomsGroups.Create.Row" );
	row.Payment = "НДС, 030";
	payments.Add ( row );
	
	return payments;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Currency = "CAD";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Customs
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Customs;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Customs groups
	// *************************
	
	p = Call ( "Catalogs.CustomsGroups.Create.Params" );
	p.Description = Env.CustomsGroup;
	p.Payments = Env.Payments;
	Call ( "Catalogs.CustomsGroups.Create", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
    p.UseCustomsGroup = true;
    p.CustomsGroup = Env.CustomsGroup;
    p.CountPackages = false;
	p.CostMethod = "FIFO";
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item2;
    p.UseCustomsGroup = true;
    p.CustomsGroup = Env.CustomsGroup;
    p.CountPackages = true;
	p.CostMethod = "FIFO";
	Call ( "Catalogs.Items.Create", p );

 	// *************************
	// Create Vendor Invoice
	// *************************
	
	p = Call ( "Documents.VendorInvoice.Buy.Params" );
	p.Date = Env.Date;
	p.Vendor = Env.Vendor;
	p.Warehouse = Env.Warehouse;
	p.Items = Env.Goods;
	p.Import = true;
	p.ID = id;
	Call ( "Documents.VendorInvoice.Buy", p );

	With ( "Vendor invoice*" );
	Put ( "#Memo", id );
	Put ( "#Rate", Env.Rate );
	Click ( "#FormPost" );
	CloseAll ();
	
	Call ( "Common.StampData", id );

EndProcedure