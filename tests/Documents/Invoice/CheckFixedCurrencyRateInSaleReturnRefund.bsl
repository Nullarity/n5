// Create USD contract with fixed currency and then Invoice / Return
// Will check currency rate over there

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A052" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region sell
p = Call ( "Documents.Invoice.Sale.Params" );
p.Customer = this.Customer;
p.Rate = 21;
goods = new Array ();
p.Items = goods;
row = Call ( "Documents.Invoice.Sale.ItemsRow" );
row.Item = this.Item;
row.Quantity = "1";
row.Price = "1500";
goods.Add ( row );
p.Action = "Post";
Call ( "Documents.Invoice.Sale", p );
#endregion

#region returnFromCustomer
With();
Click("#FormDocumentReturnCreateBasedOn");
With();
Check("#Rate", 21);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 21;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Unit = "UT";
	p.Capacity = 1;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region CreateVI
	Commando("e1cib/command/Document.VendorInvoice.Create");
	Set ( "!Vendor", this.Vendor );
	Items = Get ( "!ItemsTable" );
	Click ( "!ItemsTableAdd" );
	Items.EndEditRow ();
	Set ( "!ItemsItem", this.Item, Items );
	Set ( "!ItemsQuantityPkg", 1000, Items );
	Set ( "!ItemsPrice", 3, Items );
	Click ( "!FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
