// Check how Customer Payment returns Refund to Customer
// Customer Refund: 100 lei
// Pay to Customer (return): 100 lei

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0R1" ) );
getEnv ();
createEnv ();

#region customerRefund
Commando("e1cib/command/Document.Refund.Create");
Put ( "#Customer", this.Customer );
Put ( "#Amount", 100 );
Click ( "#FormPostAndClose" );
#endregion

#region customerPayment
Commando("e1cib/command/Document.Payment.Create");
Put ( "#Customer", this.Customer );
Put ( "#Amount", 100 );
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
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
