// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A12M" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region changeReceipt
Call ( "Documents.ReceiveItems.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
table = Get ( "#Items" );
Set ( "#ItemsPrice [1]", 10, table );
Click ( "#FormPostAndClose" );
#endregion

#region restoreCost
Commando ( "e1cib/app/DataProcessor.Cost" );
Click ( "#Restore" );
Pause ( 2 * __.Performance );
Close ();
#endregion

#region checkRetail
Call ( "Documents.RetailSales.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region resetCost
	Commando ( "e1cib/app/DataProcessor.Cost" );
	Click ( "#FormReset" );
	Close ();
	#endregion
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region receiveItems
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item;
	row.Quantity = 150;
	row.Price = 7;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Account = "6111";
	p.Items = items;
	p.Memo = id;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region saleItem
	Commando("e1cib/command/Document.Sale.Create");
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

	#region retail
	Commando("e1cib/list/Document.Sale");
	Activate ( "#Accounting" );
	Click("#Calculate");
	With ();
	Set ( "#Day", Format ( this.Date, "DLF=D" ) );
	Set ( "#Memo", id );
	Click ( "#FormOK" );
	Pause ( 2 * __.Performance );
	CheckErrors ();
	With ();
	Close ();
	#endregion
	
	RegisterEnvironment ( id );
		
EndProcedure
