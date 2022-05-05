// WriteOff Items and produce Tax Invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0PK" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region writeoff
Commando("e1cib/command/Document.WriteOff.Create");
Put("#Date", this.Date);
Put("#Warehouse", this.Warehouse);
Set("#ExpenseAccount", "7118");
Click ( "#ShowPrices" );
Pick ( "#VATUse", "Included In Price" );
Put("#VATAccount", "7131");
Set("#Customer", this.Customer);
table = Get ( "#ItemsTable" );
Click  ( "#ItemsTableAdd" );
table.EndEditRow ();
Set ( "#ItemsItem", this.Item, table );
Set ( "#ItemsQuantity", 1, table );
Set ( "#ItemsPrice", 300, table );
Click ( "#FormPost" );
#endregion

#region generateTaxInvoice
Click("#NewInvoiceRecord");
With();
Set("#Number", id+id);
Click("#FormPrint");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item;
	row.Quantity = "150";
	row.Price = "7";
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Warehouse = this.Warehouse;
	p.Account = "6111";
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
