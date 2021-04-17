// Check if VI properly closes Vendor Debts register when we buy items by PO and add some non-PO accounts
// Create PO with 1 item
// Create VI and add a record intp Accounts table
// Post VI and check records

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2BDDEC97" ) );
getEnv ();
createEnv ();

#region CreatePO
Commando ( "e1cib/command/Document.PurchaseOrder.Create" );
Set ( "#Vendor", this.Vendor );
ItemsTable = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );
Set ( "#ItemsItem", this.Item, ItemsTable );
Set ( "#ItemsQuantityPkg", 1, ItemsTable );
Set ( "#ItemsPrice", 1, ItemsTable );
ItemsTable.EndEditRow ( false );
Click ( "#FormPost" );
#endregion

#region CreateVI
Click("#FormDocumentVendorInvoiceCreateBasedOn");
With();
Activate ( "#GroupAccounts" ); // Other Assets
Accounts = Get ( "#Accounts" );
Click ( "#AccountsAdd" );
Accounts.EndEditRow ( false );
Set ( "#AccountsAccount", "7141", Accounts );
Set ( "#AccountsAmount", 100, Accounts );
Set ( "#AccountsVATCode", "20%", Accounts );
Click( "#FormPost" );
#endregion

#region CheckRecords
Click("#FormReportRecordsShow");
With();
CheckTemplate("#TabDoc");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region CreateVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Terms = "Due on receipt";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion
	
	#region CreateItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
