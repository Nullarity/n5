// Check cost sequence

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A135" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region changeReceipt
Call ( "Documents.ReceiveItems.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
table = Get ( "#Items" );
Set ( "#ItemsPrice [1]", 800, table );
Click ( "#FormPostAndClose" );
#endregion

#region restoreCost
Commando ( "e1cib/app/DataProcessor.Cost" );
Click ( "#Restore" );
Pause ( 2 * __.Performance );
Close ();
#endregion

#region checkCommissioning
Call ( "Documents.Commissioning.ListByMemo", id );
With ();
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "FixedAsset", "Fixed Asset " + id );
	this.Insert ( "Responsible", "Responsible " + id );
	this.Insert ( "Expenses", "Expenses " + id );

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
	
	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region createFixedAsset
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = this.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	#endregion
	
	#region createEmployee
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = this.Responsible;
	Call ( "Catalogs.Employees.Create", p );
	#endregion

	#region createExpenses
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Description = this.Expenses;
	Call ( "Catalogs.ExpenseMethods.Create", p );
	#endregion
	
	#region receiveItem
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Item;
	row.Quantity = 1;
	row.Price = 700;
	items.Add ( row );
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = this.Date - 86400*2;
	p.Account = "6111";
	p.Items = items;
	p.Memo = id;
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region commissioning
	Commando("e1cib/command/Document.Commissioning.Create");
	table = Activate ( "#Items" );
	Close ( "Fixed Asset" );
	Put ( "#Employee", this.Responsible );
	Put ( "#Memo", id );
	Click ( "#ItemsAdd" );
	With ( "Fixed Asset" );
	Set ( "#Item", this.Item );
	Set ( "#QuantityPkg", 1 );
	Set ( "#FixedAsset", this.FixedAsset );
	Set ( "#Expenses", this.Expenses );
	Click ( "#Charge" );
	Click ( "#FormOK" );
	With ();
	Click ( "#FormPost" );
	#endregion
	
	RegisterEnvironment ( id );

EndProcedure
