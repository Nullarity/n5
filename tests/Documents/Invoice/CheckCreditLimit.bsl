// Will test credit-limit for new and posted invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0OQ" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region testZeroLimit
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000,000.00 MDL" );
CloseAll ();
#endregion

#region setLimit
Commando("e1cib/list/Document.CreditLimit");
Click("#FormCreate");
With ();
Put ("#Amount", 1000);
Put ("#Customer", this.Customer);
Click("#FormWriteAndClose");
With();
Close ();
#endregion

#region testLimitAfterSaveAndPost
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000.00 MDL" );
Pick ( "#VATUse", "Not Applicable" );
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Services.EndEditRow ();
Set ( "#ServicesItem", this.Service, Services );
Set ( "#ServicesQuantity", 1, Services );
Set ( "#ServicesPrice", 300, Services );
Click("#JustSave");
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 700.00 MDL" );
Click("#FormPost");
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 700.00 MDL" );
Set ( "#ServicesPrice", 600, Services );
Get ( "#RestrictionLabel1" ).ClickFormattedStringHyperlink ( "Update Information" );
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 400.00 MDL" );
CloseAll ();
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
