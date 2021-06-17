// Create PO with discounts and check if it correctly migrages to Vendor Invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A04O" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPurchaseOrder
Commando("e1cib/list/Document.PurchaseOrder");
Click("#FormCreate");
With();
Put ( "#Vendor", this.Vendor );
Put ( "#Memo", id );
Services = Get ( "!Services" );
Click ( "!ServicesAdd" );
Services.EndEditRow ();
Set ( "!ServicesItem", this.Service, Services );
Set ( "!ServicesServiceDescription", this.Description, Services );
Set ( "!ServicesQuantity", 1, Services );
Set ( "!ServicesPrice", 10, Services );
Set ( "!ServicesDiscount", 5, Services );
Click("#FormPostAndClose");
#endregion

#region checkDiscount
Commando("e1cib/command/Document.VendorInvoice.Create");
Put ("#Vendor", this.Vendor);
Activate ("#Services");
Check("#Services / #ServicesDiscountRate", 50);
Check("#Services / #ServicesDiscount", 5);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Description", "Description should stay " + id );

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
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
