// Create USD contract with fixed currency rate for Customer and Vendor
// Create documents and check currency and rate

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A04W" ) );
getEnv ();
createEnv ();

#region VendorReturn
Commando("e1cib/command/Document.VendorReturn.Create");
Put("#Vendor", this.Vendor);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region VendorRefund
Commando("e1cib/command/Document.VendorRefund.Create");
Put("#Vendor", this.Vendor);
Check("#ContractCurrency", "USD");
Check("#ContractRate", 15);
#endregion

#region _Return
Commando("e1cib/command/Document.Return.Create");
Put("#Customer", this.Customer);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region PO
Commando("e1cib/command/Document.PurchaseOrder.Create");
Put("#Vendor", this.Vendor);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region Refund
Commando("e1cib/command/Document.Refund.Create");
Put("#Customer", this.Customer);
Check("#ContractCurrency", "USD");
Check("#ContractRate", 15);
#endregion

#region Quote
Commando("e1cib/command/Document.Quote.Create");
Put("#Customer", this.Customer);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region SO
Commando("e1cib/command/Document.SalesOrder.Create");
Put("#Customer", this.Customer);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region Invoice
Commando("e1cib/command/Document.Invoice.Create");
Put("#Customer", this.Customer);
Check("#Currency", "USD");
Check("#Rate", 15);
CheckState("#ContractAmount","Visible", false);
Put("#Currency", "MDL");
CheckState("#ContractAmount","Visible");
#endregion

#region VendorPayment
Commando("e1cib/command/Document.VendorPayment.Create");
Put("#Vendor", this.Vendor);
Check("#ContractCurrency", "USD");
Check("#ContractRate", 15);
#endregion

#region Payment
Commando("e1cib/command/Document.Payment.Create");
Put("#Customer", this.Customer);
Check("#ContractCurrency", "USD");
Check("#ContractRate", 15);
#endregion

#region AdjustVendorDebts
Commando("e1cib/command/Document.AdjustVendorDebts.Create");
Put("#Vendor", this.Vendor);
Check("#Currency", "USD");
Put("#Currency", "MDL");
Check("#ContractRate", 15);
#endregion

#region AdjustDebts
Commando("e1cib/command/Document.AdjustDebts.Create");
Put("#Customer", this.Customer);
Check("#Currency", "USD");
Put("#Currency", "MDL");
Check("#ContractRate", 15);
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
