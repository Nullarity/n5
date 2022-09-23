// Check advance returning and advance taking
// Get payment from customer 100 lei
// Create refund 120 lei (20 lei is advance given)

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0U2" ) );
getEnv ();
createEnv ();

#region payToCustomer
Commando("e1cib/command/Document.Payment.Create");
Put ( "#Customer", this.Customer );
Put ( "#Amount", 100 );
Click ( "#FormPostAndClose" );
#endregion

#region Refund
Commando("e1cib/command/Document.Refund.Create");
Put ( "#Customer", this.Customer );
Put ( "#Amount", 120 );
Click ( "#MarkAll" );
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
