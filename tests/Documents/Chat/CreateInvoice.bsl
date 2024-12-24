// Create a customer invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A1AH" );
this.Insert ( "ID", id );
getEnv ();

#region createInvoice
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Set ( "#Message", "Create please an invoice for customer " + this.Customer + ", phone number is 5134445558. I provided 3 hours of service """ + this.Service + """, so that include it in this invoice. My hourly rate is $120" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
#endregion

#region getInvoiceData
Pause ( 2 ); // it shows messages
Set ( "#Message", "Thank you! Can you please tell me the total amount of the invoce? I need just amount without any additional information." );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
#endregion

#region test
Pause ( 1 );
Activate ( "#GroupText" );
Pause ( 1 );
Assert ( Fetch ( "#MessagesText", Get( "#Messages" ) ) ).Contains ( 120*3 ); // 3 hours * $120
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Deploying System Lock #" + id );

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
