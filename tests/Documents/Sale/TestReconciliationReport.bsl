// Sale product to customer through bill (without 221 account) and check how it goes to Reconciliation Statement

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0MR" ) );
getEnv ();
createEnv ();

#region checkReport
p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Reconciliation Statement";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Period";
item.Period = true;
item.ValueFrom = Format ( BegOfYear(this.Date), "DLF=D" );
item.ValueTo = Format ( EndOfYear(this.Date), "DLF=D" );
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Organization";
item.Value = this.Customer;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
CheckTemplate ( "#Result" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate ()  );
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Account", "7141" );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create" );
	#endregion

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region newReceiveItems
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400;
	p.Warehouse = this.Warehouse;
	p.Account = this.Account;
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item;
	row.CountPackages = false;
	row.Quantity = 1150;
	row.Price = 5;
	items.Add ( row );
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region saleItem
	Commando("e1cib/command/Document.Sale.Create");
	Set ("#Warehouse", this.Warehouse);
	ItemsTable = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );
	With ( "Items Selection" );
	if ( Fetch ( "#AskDetails" ) = "No" ) then
		Click ( "#AskDetails" );
	endif;
	items = Get ( "#ItemsList" );
	GotoRow ( items, "Item", this.Item );
	items.Choose ();
	Pause ( 1 );
	Get ( "#FeaturesList" ).Choose ();
	With ( "Details" );
	Set ( "#QuantityPkg", 10 );
	Set ( "#Price", 25 );
	Click ( "#FormOK" );
	With ( "Items Selection" );
	Click ( "#FormOK" );
	With ();
	Click("#NewInvoiceRecord");
	Click ( "#Button0", "1?:*" );
	With ();
	Set ( "#Customer", this.Customer );
	Pick ( "#Status", "Printed" );
	Set ( "#Number", id + id );
	Click ( "#FormWriteAndClose" );
	#endregion
	
	CloseAll ();

	RegisterEnvironment ( id );

EndProcedure
