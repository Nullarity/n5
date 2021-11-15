// Create PO
// Create Vendor Payment
// Create Vendor Refund

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2C0480FC" );
env = getEnv ( id );
createEnv ( env );

#region CreateRefund
Commando("e1cib/command/Document.VendorRefund.Create");
Set("#Vendor", env.Vendor);
Next();
Set("#Amount", 300);
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "PODate", date - 86400 );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Item ", "Item " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region CreateVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Terms = "Due on receipt";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region CreateItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region CreatePO
	Commando ( "e1cib/command/Document.PurchaseOrder.Create" );
	Set ( "Date", Format ( Env.PODate, "DLF=D" ) );
	Set ( "#Vendor", Env.Vendor );
	ItemsTable = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );
	Set ( "#ItemsItem", Env.Item, ItemsTable );
	Set ( "#ItemsQuantityPkg", 1, ItemsTable );
	Set ( "#ItemsPrice", 300, ItemsTable );
	ItemsTable.EndEditRow ( false );
	Set ( "#Memo", id );
	Click ( "#FormPostAndClose" );
	#endregion
		
	#region CreatePayment
	Commando ( "e1cib/list/Document.PurchaseOrder" );
	Clear ( "#VendorFilter, #ItemFilter, #WarehouseFilter" );
	GotoRow ( "#List", "Memo", id );
	Click("#FormDocumentVendorPaymentCreateBasedOn");
	With ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
