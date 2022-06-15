// Sale product, commit this sale and check flags

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0RA" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region commit
Commando("e1cib/list/Document.Sale");
Put ( "#WarehouseFilter", this.Warehouse );
Activate ( "#Accounting" );
Click("#Calculate");
With ();
Set ( "#Day", Format ( this.Date, "DLF=D" ) );
Set ( "#Warehouse", this.Warehouse );
Set ( "#Memo", id );
Click ( "#FormOK" );
Pause ( 2 * __.Performance );
CheckErrors ();
#endregion

#region checkWarnings
With ();
Close ();
With ();
Get ( "#List" ).Choose ();
With ();
CheckState ( "#Warning", "Visible" );
Close ();
With ();
Get ( "#Accounting" ).Choose ();
With ();
CheckState ( "#Warning", "Visible" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate ()  );
	this.Insert ( "Warehouse", "Warehouse " + id );
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
	Click("#PostAndClose");
	#endregion

	RegisterEnvironment ( id );

EndProcedure
