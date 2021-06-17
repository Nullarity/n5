// Create PO with services and specific description
// Create an vendor invoice and check if service description stays

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A04J" );
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
Click("#FormPostAndClose");
#endregion

#region checkDescription
Commando("e1cib/command/Document.VendorInvoice.Create");
Put ("#Vendor", this.Vendor);
Check("#Services / #ServicesServiceDescription[1]", this.Description);
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
