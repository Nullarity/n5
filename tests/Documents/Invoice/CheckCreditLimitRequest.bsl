// Will test how credit request works

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0OM" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region sendrequest
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
Pick ( "#VATUse", "Not Applicable" );
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Services.EndEditRow ();
Set ( "#ServicesItem", this.Service, Services );
Set ( "#ServicesQuantity", 1, Services );
Set ( "#ServicesPrice", 300, Services );
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Update Information" );
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Apply for authorization of the operation" );
With ();
Click ( "#Button0" ); // Yes
With ( "Permission to Operate *" );
Click ( "#FormOK" );
#endregion

#region approveRequest
With ();
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Request sent, await resolution" );
With ( "Permission to Operate *" );
Set ( "#Resolution", "Allow" );
Click ( "#FormOK" );
#endregion

#region purpouslyIncreaseDocumentAmount
With ();
Set ( "#ServicesPrice", 400, Services );
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Update Information" );
warning = Get ( "#RestrictionLabel1" ).TitleText;
// System should see that user changed the amount and his request is'n valid anymore
Assert ( warning ).Contains ( "the document was increased" );
//Click();
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.CreateCredit = false;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createService
	p = Call("Catalogs.Items.Create.Params");
	p.Description = this.Service;
	p.Service = true;
	Call("Catalogs.Items.Create", p);
	#endregion

	RegisterEnvironment ( id );

EndProcedure
