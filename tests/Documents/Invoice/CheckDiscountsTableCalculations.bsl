// Create SO with 2% for early payment
// Receive a 100% prepayment
// Create an Invoice and check discounts table calculation

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A015" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region openNewInvoice
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
#endregion

#region testing
Check("#Benefit", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
Activate("#Discounts");
Click("#DiscountsDelete");
Check("#Benefit", 0);
Check("#BalanceDue", 8);
Click("#DiscountsRefreshDiscounts");
Check("#Benefit", 8);
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
Check("#Benefit", 12);
Check("#BalanceDue", -4);
#endregion

#region refillAndSave
Click("#DiscountsRefreshDiscounts");
Click("#JustSave");
Check("#Benefit", 8);
Check("#PaymentsApplied", 392);
Check("#BalanceDue", 0);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Unit = "UT";
	p.Capacity = 1;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createAndApproveSO
	Commando("e1cib/list/Document.SalesOrder");
	Clear("#StatusFilter");
	Click("#FormCreate");
	With();
	Put ( "#Customer", this.Customer );
	Put ( "#Memo", id );
	Items = Get ( "!ItemsTable" );
	Click ( "!ItemsTableAdd" );
	Items.EndEditRow ();
	Set ( "!ItemsItem", this.Item, Items );
	Set ( "!ItemsQuantityPkg", 40, Items );
	Set ( "!ItemsPrice", 10, Items );
	Click ( "!ItemsTableAdd" );
	
	Click("#FormSendForApproval");
	With();
	Click ( "!Button0" );
	#endregion
	
	#region approveSO
	With();
	Click ( "!FormChange" );
	With ();
	Click ( "!FormCompleteApproval" );
	With ();
	Click ( "!Button0" );
	#endregion
	
	#region paySO
	With ();
	Click ( "#FormDocumentPaymentCreateBasedOn" );
	With ();
	Click ( "!FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
