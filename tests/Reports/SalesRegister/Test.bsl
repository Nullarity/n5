// Create all kind of documents which have influence on the Report

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2C0A9D36" );
env = getEnv ( id );
createEnv ( env );

make ( "01/01/2017", "03/31/2017", env );
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Vendor", "Vendor: " + id );
	p.Insert ( "Customer", "Customer1: " + id );
	p.Insert ( "CustomerAdvance", "Customer2: " + id );
	p.Insert ( "CustomerMonthAdvance", "Customer3: " + id );
	p.Insert ( "CustomerMonthAdvanceReverse", "Customer4: " + id );
	p.Insert ( "Item20", "Item20: " + id );
	p.Insert ( "Item6", "Item6: " + id );
	p.Insert ( "ItemType1", "Type1 " + id );
	p.Insert ( "ItemType2", "Type2 " + id );
	p.Insert ( "Warehouse", "Warehouse: " + id );
	p.Insert ( "Department", "Department: " + id );
	p.Insert ( "Service", "Service " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists(id) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Company = Env.Company;
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Company = Env.Company;
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Roles
	// *************************
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Create Vendor
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Put ( "#Description", Env.Vendor );
	Put ( "#CodeFiscal", "10000111" );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#Vendor" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	form = With ( Env.Vendor + "* " );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Put ( "#Company", Env.Company );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Customers
	// *************************

	newCustomer ( Env, Env.Customer );
	newCustomer ( Env, Env.CustomerAdvance );
	newCustomer ( Env, Env.CustomerMonthAdvance );
	newCustomer ( Env, Env.CustomerMonthAdvanceReverse );

	// *************************
	// Create ItemType
	// *************************

	Commando ( "e1cib/command/Catalog.ItemTypes.Create" );
	Set ( "#Description", env.ItemType1 );
	Click ( "#FormWriteAndClose" );

	Commando ( "e1cib/command/Catalog.ItemTypes.Create" );
	Set ( "#Description", env.ItemType2 );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item20;
	p.ItemType = env.ItemType1;
	Call ( "Catalogs.Items.Create", p );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item6;
	p.ItemType = env.ItemType2;
	p.VAT = "6%";
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Vendor Invoices
	// *************************
	
	receiveItems ( Env, " 1/ 1/2017 12:00:00 AM" );
	receiveItems ( Env, " 1/ 1/2017 12:00:00 AM" );
	
	#region CreateInvoice1

	Commando ( "e1cib/data/Document.Invoice" );
	formInvoice = With ( "Invoice (create)" );
	Put ( "#Company", Env.Company );
	
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Department", Env.Department );
	Put ( "#Customer", Env.Customer );
	
	// Items
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item20, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 200, table );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item6, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 300, table );
	
	Put ( "#Date", " 1/ 1/2017 12:00:01 AM" );
	Click ( "#FormPost" );
	Put ( "#Date", " 1/ 1/2017 12:00:01 AM" );
	Click ( "#FormPost" );
	
	Click ( "#NewInvoiceRecord" );
	With ();
	Get ( "#Range" ).Clear ();
	Put ( "#Number", id + 1 );
	Put ( "#Memo", id );
	Put ( "#DeliveryDate", "03/13/2017" );
	Put ( "#Status", "Printed" );
	Click ( "#FormWriteAndClose" );
	
	Close ( formInvoice );

	#endregion
	
	#region CreateInvoice2

	Commando ( "e1cib/data/Document.Invoice" );
	formInvoice = With ( "Invoice (create)" );
	Put ( "#Company", Env.Company );
	
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Department", Env.Department );
	Put ( "#Customer", Env.Customer );
	
	// Items
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item20, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 200, table );
	
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item6, table );
	Put ( "#ItemsQuantityPkg", 1, table );
	Put ( "#ItemsPrice", 300, table );
	
	Put ( "#Date", " 1/ 1/2017 12:00:02 AM" );
	Click ( "#FormPost" );
	Put ( "#Date", " 1/ 1/2017 12:00:02 AM" );
	Click ( "#FormPost" );
	
	Click ( "#NewInvoiceRecord" );
	With ();
	Get ( "#Range" ).Clear ();
	Put ( "#Number", id + 2 );
	Put ( "#Memo", id );
	Put ( "#DeliveryDate", "03/13/2017" );
	Set ( "#Description", "Invoive #2 Descrption" );
	Put ( "#Status", "Printed" );
	Click ( "#FormWriteAndClose" );
	
	Close ( formInvoice );
	
	#endregion
	
	#region AdvanceAndInvoice
	
	// Create Payment
	Commando("e1cib/command/Document.Payment.Create");
	Put ( "#Date", " 1/ 1/2017 12:00:03 AM" );
	Set("#Company", env.Company);
	Set("#Customer", env.CustomerAdvance);
	Set("#Account", "2421");
	Set("#Currency1", "MDL");
	Set("#Amount", 1000);
	Put ( "#Date", " 1/ 1/2017 12:00:03 AM" );
	Click ( "#FormPost" );
	
	// Create Invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put ( "#Date", "01/02/2017" );
	Set ( "#Company", Env.Company );
	Set ( "#Warehouse", Env.Warehouse );
	Set ( "#Department", Env.Department );
	Set ( "#Customer", Env.CustomerAdvance );

	Put("#VATUse", 1 ); // vat included in the price
	Services = Get("#Services");
	Click("#ServicesAdd");
	Put("#ServicesItem", Env.Service, Services);
	Set("#ServicesQuantity", 1, Services);
	Set("#ServicesPrice", "1000.000", Services);
	Next();
	Click("#FormPost");
	Put ( "#Date", " 1/ 2/2017 12:00:00 AM" );
	Click("#FormPost");
	
	#endregion
	
	#region VendorPayment

	Commando("e1cib/command/Document.VendorPayment.Create");
	Put ( "#Date", "01/05/2017" );
	Set("#Company", env.Company);
	Set("#Vendor", env.Vendor);
	Set("#Account", "2421");
	Set("#Currency1", "MDL");
	Set("#Amount", 904); // Amount of two invoices
	Click("#FormPost");
	
	#endregion

	#region VendorRefund

	Commando("e1cib/command/Document.VendorRefund.Create");
	Put ( "#Date", "01/06/2017" );
	Set("#Company", env.Company);
	Set("#Vendor", env.Vendor);
	Set("#Account", "2421");
	Set("#Currency1", "MDL");
	Set("#Amount", 452); // Vendor Invoice amount
	Click("#FormPost");
	
	#endregion
	
	#region VendorReturn

	OpenMenu ( "Sections panel / Purchases" );
	OpenMenu ( "Functions menu / Vendor Invoices" );
	
	With ( "Vendor Invoices" );
	Set ( "#VendorFilter", Env.Vendor );
	Next();
	Get("#List").GotoLastRow ();
	Click ( "#FormDocumentVendorReturnCreateBasedOn" );
	With ();
	Put ( "#Date", " 1/ 7/2017 12:00:00 AM" );
	Click ( "#FormPostAndClose" );

	#endregion	
	
	#region MonthlyAdvances
	
	// Create Entry for emulating advances
	OpenMenu ( "Sections panel / Accounting" );
	OpenMenu ( "Functions menu / Entries" );
	
	With ( "Accounting Entries" );
	Click ( "#FormCreate" );
	
	With ( "Entry (create)" );
	Put ( "#Date", "01/08/2017" );
	Set ( "#Company", Env.Company );
	Records = Get ( "#Records" );
	Click ( "#RecordsAdd" );
	
	With ( "Record" );
	Set ( "#AccountDr", "2411" );
	Set ( "#AccountCr", "2211" );
	Next ();
	Set ( "#DimCr1", Env.CustomerMonthAdvance );
	Next ();
	Set ( "#Amount", 100 );
	Click ( "#FormOK" );
	
	With ( "Entry (create) *" );
	Click ( "#FormPostAndClose" );


	// Create advance balance in 2016
	With ( "Accounting Entries" );
	Click ( "#FormCreate" );
	
	With ( "Entry (create)" );
	Put ( "#Date", "12/31/2016" );
	Set ( "#Company", Env.Company );
	Records = Get ( "#Records" );
	Click ( "#RecordsAdd" );
	
	With ( "Record" );
	Set ( "#AccountDr", "2411" );
	Set ( "#AccountCr", "5231" );
	Next ();
	Set ( "#DimCr1", Env.CustomerMonthAdvanceReverse );
	Next ();
	Set ( "#Amount", 100 );
	Click ( "#FormOK" );
	
	With ( "Entry (create) *" );
	Click ( "#FormPostAndClose" );
	
	// In January that advance should be reversed
	With ( "Accounting Entries" );
	Click ( "#FormCreate" );
	
	With ( "Entry (create)" );
	Put ( "#Date", "01/10/2017" );
	Set ( "#Company", Env.Company );
	Records = Get ( "#Records" );
	Click ( "#RecordsAdd" );
	
	With ( "Record" );
	Set ( "#AccountDr", "2211" );
	Set ( "#AccountCr", "6118" );
	Next ();
	Set ( "#DimDr1", Env.CustomerMonthAdvanceReverse );
	Next ();
	Set ( "#Amount", 100 );
	Click ( "#FormOK" );
	
	With ( "Entry (create) *" );
	Click ( "#FormPostAndClose" );

	// Close Advances Taken
	OpenMenu ( "Sections panel / Accounting" );
	OpenMenu ( "Functions menu / Periodic Calculations" );
	
	With ( "Periodic Calculations" );
	Click ( "#FormCreateByParameterClosingAdvances" );
	
	With ( "Closing Advances (create)" );
	Put ( "#Date", "01/31/2017" );
	Set ( "#Company", Env.Company );
	Click ( "#AdvancesFill" );
	
	With ( "Closing Advances: Setup Filters" );
	Click ( "#FormFill" );
	Pause ( 1 * __.Performance );
	With ();
	Click ( "#FormPostAndClose" );

	#endregion
	
	// *************************
	// Create VATSale
	// *************************
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "03/04/2017" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "AB1" );
	Put ( "#FormNumber", id );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "20%" );
	Put ( "#Description", "Some description" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "03/05/2017" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "AB2" );
	Put ( "#FormNumber", id );
	Put ( "#Amount", "1000" );
	Put ( "#VATCode", "0%" );
	Click ( "#FormWriteAndClose" );
	
	Commando ( "e1cib/data/Document.VATSales" );
	With ( "VAT on Sales (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Date", "03/06/2017" );
	Put ( "#Customer", Env.Customer );
	Put ( "#Series", "AB3" );
	Put ( "#FormNumber", id );
	Put ( "#Amount", "600" );
	Put ( "#VATCode", "6%" );
	Click ( "#FormWriteAndClose" );
	
	RegisterEnvironment(id);

EndProcedure

Procedure newCustomer ( Env, Customer )

	Commando ( "e1cib/data/Catalog.Organizations" );
	Put ( "#Description", Customer );
	Put ( "#CodeFiscal", "10000222" );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#Customer" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	With ( Customer + "* " );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Set ( "#Company", Env.Company );
	Next ();
	Click ( "#FormWriteAndClose" );

EndProcedure

Procedure receiveItems ( Env, Date )

	Commando ( "e1cib/data/Document.VendorInvoice" );
	With ( "Vendor Invoice (create)" );
	Put ( "#Date", Date );
	Put ( "#Company", Env.Company );
	Put ( "#ReferenceDate", "03/13/2017" );
	Put ( "#Series", "AB" );
	Put ( "#Reference", "005" );
	Put ( "#Warehouse", Env.Warehouse );
	Put ( "#Vendor", Env.Vendor );

	// Items
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item20, table );
	Put ( "#ItemsQuantityPkg", 2, table );
	Put ( "#ItemsPrice", 100, table );

	Click ( "#ItemsTableAdd" );

	Put ( "#ItemsItem", env.Item6, table );
	Put ( "#ItemsQuantityPkg", 2, table );
	Put ( "#ItemsPrice", 100, table );

	Click ( "#FormPost" );
	Put ( "#Date", Date );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure make ( Date1, Date2, Env )

	p = Call ( "Common.Report.Params" );
	p.Path = "Accounting / Sales Register";
	p.Title = "Sales Register*";
	filters = new Array ();
	
	item = Call ( "Common.Report.Filter" );
	item.Name = "Company";
	item.Value = Env.Company;
	filters.Add ( item );
	
	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date1;
	item.ValueTo = Date2;
	filters.Add ( item );

	p.Filters = filters;
	
	form = With ( Call ( "Common.Report", p ) );

EndProcedure
