// Create document from list and then create return

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0L1" ) );
getEnv ();
createEnv ();

#region saleItem
Commando("e1cib/list/Document.Sale");
Click("#FormCreate");
With();
ItemsTable = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );
ItemsTable.EndEditRow ();
Set ( "#ItemsItem", this.Item, ItemsTable );
Set ( "#ItemsQuantityPkg", 10, ItemsTable );
Set ( "#ItemsPrice", 25, ItemsTable );
Click("#FormPost");
amount = Number ( Fetch("#Amount") );
#endregion

#region returnItem
Click("#FormCopy");
With();
Check("#Return", "Yes");
Check("#ItemsTable / #ItemsQuantityPkg [ 1 ]", -10);
Click("#FormPost");
reverseAmount = Number ( Fetch("#Amount") );
Assert(amount + reverseAmount, "Sale and Reverse amount should be opposite").Equal(0);
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate ()  );
	this.Insert ( "Warehouse", "Main" );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Account", "7141" );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
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
