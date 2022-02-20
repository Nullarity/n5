// Create document from list and then create return

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0O7" ) );
getEnv ();
createEnv ();

#region saleItem
Commando("e1cib/list/Document.Sale");
Set ("#WarehouseFilter", this.Warehouse);
Next ();
Click("#ListCreate");
With();
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
amount = Number ( Fetch("#Amount") );
Click("#PostAndClose");
#endregion

#region returnItem
With ();
Click("#ListCopy");
With();
Check("#Return", "Yes");
Check("#ItemsTable / #ItemsQuantityPkg [ 1 ]", -10);
reverseAmount = Number ( Fetch("#Amount") );
Assert(amount + reverseAmount, "Sale and Reverse amount should be opposite").Equal(0);
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
	Call ( "Catalogs.Warehouses.Create", p );
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

	RegisterEnvironment ( id );

EndProcedure
