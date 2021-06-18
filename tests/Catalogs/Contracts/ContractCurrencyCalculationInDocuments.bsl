// Create USD contract and then create documents in MDL and check
// if ContractAmount is calculating

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A04Y" ) );
getEnv ();
createEnv ();

#region Quote
Commando("e1cib/command/Document.Quote.Create");
Put("#Customer", this.Customer);
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesAmount [1]", 100);
Check("#ContractAmount", 6.67);
#endregion

#region SO
Commando("e1cib/command/Document.SalesOrder.Create");
Put("#Customer", this.Customer);
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesAmount [1]", 100);
Check("#ContractAmount", 6.67);
#endregion

#region Invoice
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesAmount [1]", 100);
Check("#ContractAmount", 6.67);
#endregion

#region VendorInvoice
Commando("e1cib/command/Document.VendorInvoice.Create");
Put("#Vendor", this.Vendor);
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesAmount [1]", 100);
Check("#ContractAmount", 6.67);
#endregion

#region PO
Commando("e1cib/command/Document.PurchaseOrder.Create");
Put("#Vendor", this.Vendor);
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesAmount [1]", 100);
Check("#ContractAmount", 6.67);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Vendor", "Vendor " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 15;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createVendor
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.Vendor;
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 15;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
