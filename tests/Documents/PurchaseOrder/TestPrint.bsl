Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6A981F" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.PurchaseOrder" );
formMain = With ();
Put ( "#Company", Env.Company );
Put ( "#Department", Env.Department );
Put ( "#Vendor", Env.Vendor );
Put ( "#Warehouse", env.Warehouse );

table = Get ( "#Services" );
Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Item, table );
Put ( "#ServicesQuantity", 10, table );
Put ( "#ServicesPrice", 100, table );

Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Item, table );
Put ( "#ServicesQuantity", 5, table );
Put ( "#ServicesPrice", 200, table );
Next ();
Click ( "#JustSave" );
Click ( "#FormDocumentPurchaseOrderPurchaseOrder" );
With ();
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Service " + ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Vendor", "Vendor: " + ID );
	p.Insert ( "PaymentAddress", "Payment Address: " + ID );
	p.Insert ( "ShippingAddress", "Shipping Address: " + ID );
	p.Insert ( "Department", "Department: " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Put ( "#Description", Env.Vendor );
	Click ( "#Vendor" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Company
	// *************************
	Call ( "Catalogs.Companies.Create", Env.Company );

	// *************************
	// Create Warehouse
	// *************************
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	p.Company = Env.Company;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Addresses
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.PaymentAddress );
	setValue ( "#Owner", Env.Company, "Companies" );
	Click ( "#FormWriteAndClose" );

	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ();
	Click ( "#Manual" );
	Put ( "#Address", Env.ShippingAddress );
	setValue ( "#Owner", Env.Warehouse, "Warehouses" );
	Click ( "#FormWriteAndClose" );
	
	// Complete Company
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( Env.Company + "*" );
	Put ( "#PaymentAddress", Env.PaymentAddress );
	Click ( "#FormWriteAndClose" );

	// Complete Warehouse
	Commando ( "e1cib/list/Catalog.Warehouses" );
	With ();

	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Warehouse;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Put ( "#Address", Env.ShippingAddress );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Roles
	// *************************
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Accounant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Company = Env.Company;
	Call ( "Catalogs.Departments.Create", p );

	Call ( "Common.StampData", id );

EndProcedure

Procedure setValue ( Field, Value, Object, GoToRow = "Description" )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", Object );
	Click ( "#OK" );
	if ( Object = "Companies" ) then
		With ( "Addresses*" );
		Put ( "#Owner", Value );
	else
		With ( Object );
		GotoRow ( "#List", GoToRow, Value );
		Click ( "#FormChoose" );
		CurrentSource = form;
	endif;
	
EndProcedure