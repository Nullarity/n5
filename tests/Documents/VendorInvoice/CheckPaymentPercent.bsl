// Create an Invoice
// Pay it 70%
// Check Payment % in the Invoices list

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2B820C7F" ) );

getEnv ();
createEnv ();

Commando("e1cib/list/Document.VendorInvoice");
Click ( "#FormCreate" );
With ();
Set ( "#Vendor", this.Vendor );
Activate ( "#GroupServices" ); // Services
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Services.EndEditRow ();
Set ( "#ServicesItem", this.Item, Services );
Set ( "#ServicesQuantity", "1", Services );
Set ( "#ServicesPrice", 100, Services );
Set ( "#ServicesExpense", "Others", Services );
Click ( "#FormPostAndClose" );

journal = With ( "Vendor Invoices" );
List = Get ( "#List" );

Assert ( Fetch ( "#PaidPercent", List ) ).Empty ();

// Create 70% payment

Click ( "#FormDocumentVendorPaymentCreateBasedOn" );
With ();
Set ( "#Amount", 70 );
Click ( "#FormPostAndClose" );

// Check list field
With ( journal );
Click ( "#FormRefresh" );
Assert ( Fetch ( "#PaidPercent", List ) ).Equal ( "70%" );

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
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	#endregion
	
	#region CreateItem

	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

	#endregion

	RegisterEnvironment ( id );

EndProcedure
