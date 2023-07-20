// Register the Discount and check the report
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A179" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region discountsReport
p = Call ( "Common.Report.Params" );
p.Path = "Sales / Reports / Discounts";
p.Title = "Discounts*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Customer";
item.Value = this.Customer;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Discount as Item";
item.Value = this.DiscountItem;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
#endregion

#region checkReport
With ();
CheckTemplate ( "#Result" );
#endregion


// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "DiscountItem", "Discount " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );

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
	#region createDiscountItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.DiscountItem;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item1;
	row.Quantity = 150;
	row.Price = 7;
	items.Add ( row );
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item2;
	row.Quantity = 150;
	row.Price = 15;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Account = "6111";
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region createDiscount
	Commando("e1cib/command/Document.Discounts.Create");
	Set ( "#Date", this.Date - 100 );
	table = Get ( "#Scale" );
	Click  ( "#ScaleAdd" );
	table.EndEditRow ();
	Set ( "#ScaleFrom", 1, table );
	Set ( "#ScaleTo", 5000, table );
	Set ( "#ScalePercent", 5, table );
	Click  ( "#ScaleAdd" );
	table.EndEditRow ();
	Set ( "#ScaleFrom", 5001, table );
	Set ( "#ScaleTo", 15000, table );
	Set ( "#ScalePercent", 10, table );

	table = Get ( "#Items" );
	Click  ( "#ItemsAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Click  ( "#ItemsAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Click ( "#FormPostAndClose" );
	#endregion

	#region createInvoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date);
	Put("#Customer", this.Customer);
	Put("#Memo", id);
	table = Get ( "#ItemsTable" );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item1, table );
	Set ( "#ItemsQuantity", 50, table );
	Set ( "#ItemsPrice", 300, table );
	Click  ( "#ItemsTableAdd" );
	table.EndEditRow ();
	Set ( "#ItemsItem", this.Item2, table );
	Set ( "#ItemsQuantity", 80, table );
	Set ( "#ItemsPrice", 500, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
