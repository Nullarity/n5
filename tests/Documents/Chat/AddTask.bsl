// Add a new task. Testing Anthropic

Call ( "Common.Init" );
CloseAll ();

#region createTask
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Anthony-sonet" );
Set ( "#Message", "Remind me to call my partner tomorrow" );
Click ( "#FormSend" );
if ( __.TestServer ) then
	Pause ( 15 );
endif;
#endregion
