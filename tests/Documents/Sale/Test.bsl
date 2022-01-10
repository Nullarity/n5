// Create & post simple Sale

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0L0" ) );
getEnv ();
createEnv ();

#region makeSake
Commando("e1cib/command/Document.Sale.Create");
ItemsTable = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );
ItemsTable.EndEditRow ();
Set ( "#ItemsItem", this.Item, ItemsTable );
Set ( "#ItemsQuantityPkg", 5, ItemsTable );
Set ( "#ItemsPrice", 25, ItemsTable );
Click ( "#FormPost" );
#endregion

// *************************
// Procedures
// *************************

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
	row.Quantity = "150";
	row.Price = "5";
	items.Add ( row );
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
