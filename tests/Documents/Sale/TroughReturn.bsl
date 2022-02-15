// Create Bill trough Return

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0MD" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region bill
Call("Documents.Return.ListByMemo", id);
With();
Click("#FormChange");
With();
amount = Fetch("#Amount");
Click ( "#FormDocumentSaleCreateBasedOn" );
With ();
CheckState("#NewInvoiceRecord", "Visible", false);
Check("#Amount", - amount);
CheckState("#Links", "Visible");
Click ( "#PostAndClose" );
With ();
CheckState("#Links", "Visible"); // Return should show the Sale in the url
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
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

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region sell
	Commando("e1cib/command/Document.Invoice.Create");
	Set("#Customer", this.Customer);
	Set("#Memo", this.ID);
	Next ();
	ItemsTable = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );
	ItemsTable.EndEditRow ();
	Set ( "#ItemsItem", this.Item, ItemsTable );
	Set ( "#ItemsQuantityPkg", 1, ItemsTable );
	Set ( "#ItemsPrice", 50, ItemsTable );
	Click("#FormPost");
	#endregion

	#region returnFromCustomer
	Click ( "#FormDocumentReturnCreateBasedOn" );
	With();
	Set("Memo", this.ID);
	Click("#FormPostAndClose");
	#endregion
	
	CloseAll ();

	RegisterEnvironment ( id );

EndProcedure
