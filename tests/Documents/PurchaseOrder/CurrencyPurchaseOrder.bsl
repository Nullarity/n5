// Check PO in currency

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A038" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPurchaseOrder
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
Call("Documents.PurchaseOrder.ListByMemo", id);
With ();
Click ( "!FormDocumentVendorPaymentCreateBasedOn" );
With ();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive1
Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Next ();
Items = Get ( "!ItemsTable" );
Assert ( Call("Table.Count", Items ) ).Not_ ().Empty ();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive2
Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Next ();
Items = Get ( "!ItemsTable" );
Assert ( Call("Table.Count", Items ) ).Empty ();
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
	
	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Terms = "Due on receipt";
	p.Currency = "EUR";
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
