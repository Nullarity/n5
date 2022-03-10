// Sale customer once and then the second time. Check if system warns user about unsigned contract

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0OD" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region secondSale
Commando("e1cib/command/Document.Invoice.Create");
Set("#Customer", this.Customer);
Next ();
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.ContractSigned = false;
	p.ContractDateStart = CurrentDate () - 86400;
	p.ContractDateEnd = EndOfYear ( CurrentDate () );
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region Sale
	p = Call ( "Documents.Invoice.Sale.Params" );
	p.Customer = this.Customer;
	services = new Array ();
	row = Call ( "Documents.Invoice.Sale.ServicesRow" );
	row.Item = "Service " + id;
	row.Quantity = 1;
	row.Price = 500;
	services.Add ( row );
	p.Services = services;
	Call ( "Documents.Invoice.Sale", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
