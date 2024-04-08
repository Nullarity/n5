// Check how much is 2+2

Call ( "Common.Init" );
CloseAll ();
#region chat
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Set ( "#Message", "How much is 2 + 2" );
Click ( "#FormSend" );
#endregion
Pause ( 5 );
#region test
Assert ( Fetch ( "#MessagesText", Get( "#Messages" ) ) ).Contains ( 4 );
#endregion