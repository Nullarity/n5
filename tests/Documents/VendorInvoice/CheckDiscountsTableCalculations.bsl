// Create PO with 2% for early payment
// Pay 100% prepayment
// Create a Vendor Invoice and check discounts table calculation

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A025" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region openNewInvoice
Commando("e1cib/command/Document.VendorInvoice.Create");
Put("#Vendor", this.Vendor);
#endregion

#region testing
Check("#Discount", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
Activate("#Discounts");
Click("#DiscountsDelete");
Check("#Discount", 0);
Check("#BalanceDue", 8);
Click("#DiscountsRefreshDiscounts");
Check("#Discount", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
discounts = Get("#Discounts");
Put("#DiscountsVATCode", "8%", discounts);
Check("#DiscountsVAT", 0.59, discounts);
Put("#DiscountsItem", "Discounts", discounts);
Check("#DiscountsVATCode", "20%", discounts);
Put("#DiscountsAmount", 12, discounts);
Check("#DiscountsVAT", 2, discounts);
Pick("#VATUse", 0);
Pick("#VATUse", 1);
Check("#DiscountsVAT", 2, discounts);
Check("#Discount", 12);
Check("#BalanceDue", -4);
#endregion

#region refillAndSave
Click("#DiscountsRefreshDiscounts");
Click("#JustSave");
Check("#Discount", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
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

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Unit = "UT";
	p.Capacity = 1;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createAndApproveSO
	Commando("e1cib/list/Document.PurchaseOrder");
	Click("#FormCreate");
	With();
	Put ( "#Vendor", this.Vendor );
	Put ( "#Memo", id );
	Items = Get ( "!ItemsTable" );
	Click ( "!ItemsTableAdd" );
	Items.EndEditRow ();
	Set ( "!ItemsItem", this.Item, Items );
	Set ( "!ItemsQuantityPkg", 40, Items );
	Set ( "!ItemsPrice", 10, Items );
	Click("#FormPostAndClose");
	#endregion
	
	#region payPO
	With ();
	Click ( "#FormDocumentVendorPaymentCreateBasedOn" );
	With ();
	Click ( "!FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
