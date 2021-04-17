// Test discount recalculation in tabular sections of SO, Quote, Invoice and others

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CEDDCED" ) );
getEnv ();
createEnv ();

list = new Array ();
list.Add ( "SalesOrder" );
list.Add ( "Invoice" );
list.Add ( "Quote" );

for each document in list do
	Commando("e1cib/command/Document." + document + ".Create");
	Set("!Customer", this.Customer);
	if (document="Quote") then
		table = Get("!Items");
		Click("!ItemsAdd");
	else
		table = Get("!ItemsTable");
		Click("!ItemsTableAdd");
	endif;
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
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
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
