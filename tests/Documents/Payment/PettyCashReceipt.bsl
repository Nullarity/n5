// Create a new Customer Payment
// Fill Cash Receipt

Call ( "Common.Init" );
CloseAll ();
this.Insert ( "ID", Call ( "Common.ScenarioID", "2A57A3B0" ) );
getEnv ();
createEnv ();

// Create Customer Payment
Commando ( "e1cib/command/Document.Payment.Create" );
Put ( "#Customer", this.Customer );
Pick ( "#Method", "Cash" );
Set ( "#Amount", "300" );
Click ( "#NewReceipt" );

// Receipt
With ();
Set ( "#Reason", "Reason" );
Set ( "#Reference", "Reference" );

// Check values
Check ( "#Giver", this.Customer );
Assert ( Fetch ( "#Director" ) ).Filled ();
Assert ( Fetch ( "#Responsible" ) ).Filled ();
Assert ( Fetch ( "#Accountant" ) ).Filled ();

// Save Receipt & Customer Payment
Click ( "#FormOK" );
With ();
Click ( "#FormPostAndClose" );

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
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure
