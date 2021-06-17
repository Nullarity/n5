// Create SO with services and specific description
// Create an invoice and check if service description stays

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A04H" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newSalesOrder
Commando("e1cib/list/Document.SalesOrder");
Clear("#StatusFilter");
Click("#FormCreate");
With();
Put ( "#Customer", this.Customer );
Put ( "#Memo", id );
Services = Get ( "!Services" );
Click ( "!ServicesAdd" );
Services.EndEditRow ();
Set ( "!ServicesItem", this.Service, Services );
Set ( "!ServicesServiceDescription", this.Description, Services );
Set ( "!ServicesQuantity", 1, Services );
Set ( "!ServicesPrice", 10, Services );
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

#region checkDescription
Commando("e1cib/command/Document.Invoice.Create");
Put ("#Customer", this.Customer);
Check("#Services / #ServicesServiceDescription[1]", this.Description);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Description", "Description should stay " + id );

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
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
