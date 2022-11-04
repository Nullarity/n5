﻿// Will sell items to person and orgnization in the Shop where Cash Receips document are used

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "B0RG" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region commit
Commando("e1cib/list/Document.Sale");
Put ( "#WarehouseFilter", this.Warehouse );
Clear ( "#LocationFilter" );
Activate ( "#Accounting" );
Click("#Calculate");
With ();
Set ( "#Day", Format ( this.Date, "DLF=D" ) );
Set ( "#Warehouse", this.Warehouse );
Clear ( "#Location" );
Click ( "#FormOK" );
Pause ( 2 * __.Performance );
CheckErrors ();
With ();
Close ();
#endregion

#region checking
With ();
Click ( "#AccountingChange" );
With ();
CheckState ( "#Receipt", "Visible" );
Check ( "#Amount", 250 ); // only one record should be in the table (the second one was sold though Invoice + Payment + Cash Receipt)
Close ();
With ();
Click ( "#AccountingReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Location", "Location " + id );
	this.Insert ( "Customer", "Customer " + id );
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

	#region newLocation
	p = Call ("Catalogs.PaymentLocations.Create.Params" );
	p.Description = this.Location;
	p.Account = "2411";
	Call ("Catalogs.PaymentLocations.Create", p );
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
	row.Quantity = 150;
	row.Price = 5;
	items.Add ( row );
	p.Items = items;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region sellToCustomer
	Commando("e1cib/command/Document.Invoice.Create");
	Set("#Customer", this.Customer);
	Set("#Warehouse", this.Warehouse);
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

	#region billCustomer
	Click ( "#FormDocumentSaleCreateBasedOn" );
	With();
	Set("#Location", this.Location);
	Click ( "#PostAndClose" );
	#endregion

	#region receivePayment
	With();
	Click ("#CreatePayment");
	With ();
	Set("#Location", this.Location);
	Set("#Method", "Cash");
	Set("#Amount", 50);
	Click("#FormPostAndClose");
	#endregion

	#region sellToIndividual
	Commando("e1cib/command/Document.Sale.Create");
	Set("#Warehouse", this.Warehouse);
	Set("#Location", this.Location);
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
	
	CloseAll ();

	RegisterEnvironment ( id );

EndProcedure
