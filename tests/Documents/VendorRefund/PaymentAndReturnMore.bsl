// Check advance returning and advance taking with VAT records
// Pay to Vendor: 100 lei
// Vendor Refund: 120 lei (20 lei is advance taken)

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0VH" ) );
getEnv ();
createEnv ();

#region payToVendor
Commando("e1cib/command/Document.VendorPayment.Create");
Put ( "#Vendor", this.vendor );
Put ( "#Amount", 100 );
Click ( "#FormPostAndClose" );
#endregion

#region venorRefund
Commando("e1cib/command/Document.VendorRefund.Create");
Put ( "#Vendor", this.vendor );
Put ( "#Amount", 120 );
Click("#Payments / #PaymentsPay[1]");
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Vendor", "Vendor " + id );

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

	RegisterEnvironment ( id );

EndProcedure
