// Test discount recalculation in tabular sections of SO, Quote, Invoice and others

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A04Q" ) );
getEnv ();
createEnv ();

list = new Array ();
list.Add ( "PurchaseOrder" );
list.Add ( "VendorInvoice" );

for each document in list do
	Commando("e1cib/command/Document." + document + ".Create");
	Set("!Vendor", this.Vendor);
	table = Get("!ItemsTable");
	Click("!ItemsTableAdd");
	table.EndEditRow();
	Set("!ItemsItem", this.Item, table);
	Set("!ItemsQuantityPkg", 1, table);
	Set("!ItemsPrice", 100, table);
	Set("!ItemsDiscountRate", 10, table);
	Check("!ItemsDiscount", 10, table);
	Check("!ItemsAmount", 90, table);

	// Change qty and check discount
	Set("!ItemsQuantityPkg", 2, table);
	Check("!ItemsAmount", 180, table);

	// Change units and check discount
	Set("!ItemsQuantity", 20, table);
	Check("!ItemsQuantityPkg", 4, table);
	Check("!ItemsAmount", 360, table);

	table = Get("!Services");
	Click("!ServicesAdd");
	table.EndEditRow();
	Set("!ServicesItem", this.Service, table);
	Set("!ServicesQuantity", 1, table);
	Set("!ServicesPrice", 100, table);
	Set("!ServicesDiscountRate", 10, table);
	Check("!ServicesDiscount", 10, table);
	Check("!ServicesAmount", 90, table);

	// Change qty and check discount
	Set("!ServicesQuantity", 2, table);
	Check("!ServicesAmount", 180, table);
enddo;

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
