Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.VendorInvoice" );
With ( "Vendor Invoices" );
Put ( "#VendorFilter", env.Vendor );
Click ( "#FormDocumentIntangibleAssetsCommissioningCreateBasedOn" );

form = With ( "Intangible Assets Commissioning (create)" );
Put ( "#Warehouse", env.Warehouse );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Activate ( "#Items" );
Click ( "#ItemsEdit" );
With ( "Intangible Asset" );
Put ( "#Quantity", 10 );
Put ( "#IntangibleAsset", env.AssetNotPosted );
Click ( "#FormOK" );

With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Intangible Assets Commissioning #*" );
Call ( "Common.CheckLogic", "#TabDoc" );
With ( form );
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", " 272B2D2D#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "Expense", "_Expense: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Items", getItems ( id ) );
	p.Insert ( "Vendor", "_Vendor: " + id );
	p.Insert ( "IntangibleAssets", getAssets ( "_Intangible Asset", p ) );
	p.Insert ( "AssetNotPosted", "_AssetNotPosted: " + id );
	return p;

EndFunction

Function getItems ( ID )

	rows = new Array ();
	rows.Add ( rowItem ( "_Item1: " + ID, 10, 100 ) );
	return rows;

EndFunction

Function rowItem ( Item, Quantity, Price, CountPackages = false )

	row = Call ( "Documents.VendorInvoice.Create.ItemsRow" );
	row.Item = Item;
	row.Quantity = Quantity;
	row.Price = Price;
	row.Account = "15100";
	row.Insert ( "CountPackages", CountPackages );
	return row;

EndFunction

Function getAssets ( AssetName, Env )

	id = Env.ID;
	rows = new Array ();
	p = Call ( "Documents.VendorInvoice.Create.AssetsRow" );
	p.Department = Env.Department;
	p.Item = AssetName +"1: " + id;
	p.Employee = Env.Employee;
	p.Amount = 10000;
	rows.Add ( p );
	p = Call ( "Documents.VendorInvoice.Create.AssetsRow" );
	p.Department = Env.Department;
	p.Item = AssetName +"2: " + id;
	p.Employee = Env.Employee;
	p.Amount = 20000;
	rows.Add ( p );
	return rows;

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
	//p.Currency = "CAD";
	Call ( "Catalogs.Organizations.CreateVendor", p );


	// *************************
	// Create IntangibleAssets
	// *************************
	for each row in Env.IntangibleAssets do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = row.Item;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.AssetNotPosted;
	Call ( "Catalogs.IntangibleAssets.Create", p );		

	// *************************
	// Create Vendorinvoice
	// *************************

	p = Call ( "Documents.VendorInvoice.Create.Params" );
	FillPropertyValues ( p, Env );
	p.TaxGroup = "California";
	Call ( "Documents.VendorInvoice.Create", p );
	form = With ( "Vendor Invoice*" );
 	
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );
	
EndProcedure

