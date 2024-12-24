// Set a new credit limit

Call ( "Common.Init" );
CloseAll ();
id = Call ( "Common.ScenarioID", "A1AT" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region createCreditLimit
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Anthony-sonet" );
Set ( "#Message", "Set please a new credit limit to 0 for customer " + this.customer );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
#endregion

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