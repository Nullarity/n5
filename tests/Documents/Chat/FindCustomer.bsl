// Find customer by name and then by phone

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A1A4" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();
this.Insert ( "Data", EnvironmentData ( id ) );

//goto ~phone;

#region searchingByName
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Set ( "#Message", "find please a customer by name " + id + " and tell me please his id" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
test ();
#endregion

CloseAll ();

~phone:

#region searchingByPhone
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Set ( "#Message", "find please a customer by phone " + Right ( this.Data.Phone, 7 ) + " and tell me please his id" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
test ();
#endregion

Procedure test ()

	Activate ( "#GroupText" );
	Pause ( 2 ); // wait for visualization of comming messages
	Assert ( Fetch ( "#MessagesText", Get( "#Messages" ) ) ).Contains ( this.Data.Code );
	
EndProcedure

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
	phone = Right ( Format ( CurrentUniversalDateInMilliseconds (), "NG=0" ), 10 );
	// (123) 456-78-90
	phone = "(" + Left ( phone, 3 ) + ") " + Mid ( phone, 4, 3 ) + "-" + Mid ( phone, 7, 2 ) + "-" + Mid ( phone, 9, 2 );
	p.Phone = phone;
	data = Call ( "Catalogs.Organizations.CreateCustomer", p );
	code = data.Code;
	#endregion

	RegisterEnvironment ( id, new Structure ( "Code, Phone", code, phone ) );

EndProcedure
