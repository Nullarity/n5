// Create a contract in USD with fixed currency 15 lei
// Create a PO in MDL then receive a payment in MDL
// Create the first Vendor Invoice in MDL for 50% amount and check PO status
// Create the second Vendor Invoice right from PO and check totals

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A00L" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPurchaseOrder
Commando("e1cib/list/Document.PurchaseOrder");
Clear("#WarehouseFilter");
Click("#FormCreate");
With();
Put ( "#Vendor", this.Vendor );
Put ( "#Currency", "MDL" );
Check("#Rate", 15);
Put ( "#Memo", id );
Items = Get ( "!ItemsTable" );
Click ( "!ItemsTableAdd" );
Items.EndEditRow ();
Set ( "!ItemsItem", this.Item, Items );
Set ( "!ItemsQuantityPkg", 20, Items );
Set ( "!ItemsPrice", 10, Items );

Click("#FormPostAndClose");
#endregion

#region payPO
With ();
Click ( "#FormDocumentVendorPaymentCreateBasedOn" );
With ();
Click ( "!FormPostAndClose" );
#endregion

#region firstInvoice50percent
Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Next ();
Items = Get ( "!ItemsTable" );
Assert ( Call("Table.Count", Items ) ).Not_ ().Empty ();
Check ( "#PaymentsApplied", 13.33 );
Check("#Currency", "USD");
Check("#Rate", 15);
Put("#Currency", "MDL");
Check ( "#ContractAmount", 13.33 );
Check ( "#PaymentsApplied", 13.33 );
Check ( "#BalanceDue", 0 );
Activate ( "#ItemsTable" );
Set ( "!ItemsQuantityPkg", 10, Items );
Click ( "!FormPostAndClose" );
#endregion

#region checkShippingPercent
Call("Documents.PurchaseOrder.ListByMemo", id);
With();
Check("#List / #ShippedPercent", "50%");
#endregion

#region checkBalanceDue
Click("#FormChange");
With();
Check("#BalanceDue", 0);
#endregion

#region secondInvoice50percent
Click("#FormVendorInvoice");
With();
Check ( "#ContractAmount", 6.67 );
Check ( "#PaymentsApplied", 6.66 );
Check ( "#BalanceDue", 0.01 );
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
	p.Terms = "Due on receipt";
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 15;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Unit = "UT";
	p.Capacity = 1;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
