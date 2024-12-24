// Approve permission request

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A1AZ" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region approve
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Anthony-sonet" );
Set ( "#Message", "Tell me please which permission requests we have for 2017?" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
Set ( "#Message", "Ok, approve all of them" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
#endregion

#region checkIfAllowed
Commando ( "e1cib/command/Document.Invoice.Create" );
Set ( "#Date", " 1/01/2017 12:00:00 AM" );
Next ();
Get ( "#AccessLabel" ).ClickFormattedStringHyperlink ( "The restriction ""Period is closed"" has been temporarily removed" );
#endregion

Procedure getEnv ()

	id = this.ID;

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	#region sendRequest
	Commando ( "e1cib/command/Document.Invoice.Create" );
	Set ( "#Date", " 1/01/2017 12:00:00 AM" );
	Next ();
	Get ( "#AccessLabel" ).ClickFormattedStringHyperlink ( "Apply for authorization of the operation" );
	With ( "Open Period" );
	table = Get ( "", , "Table" );
	search = new Map ();
	search [ "Column1" ] = "For the day";
	table.GotoRow ( search );
	Click ( "OK" );
	With ( "Permission to Change*" );
	Click ( "#FormOK" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure