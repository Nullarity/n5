// Create an Invoice
// Pay it 70%
// Check Payment % in the Invoices list

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2B81EAA7" ) );

getEnv ();
createEnv ();

Commando("e1cib/list/Document.Invoice");
Click ( "#FormCreate" );
With ();
Set ( "#Customer", this.Customer );
Activate ( "#GroupServices" ); // Services
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Set ( "#ServicesItem", this.Item, Services );
Set ( "#ServicesQuantity", "1", Services );
Set ( "#ServicesPrice", 100, Services );
Click ( "#FormPostAndClose" );

journal = With ( "Invoices" );
List = Get ( "#List" );

Assert ( Fetch ( "#PaidPercent", List ) ).Empty ();

// Create 70% payment

Click ( "#FormDocumentPaymentCreateBasedOn" );
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
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region CreateCustomer
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	#endregion
	
	#region CreateItem

	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

	#endregion

	RegisterEnvironment ( id );

EndProcedure
