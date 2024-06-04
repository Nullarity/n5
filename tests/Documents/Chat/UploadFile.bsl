// Check file uploading

Call ( "Common.Init" );
CloseAll ();
#region createFile
text = new TextDocument ();
text.SetText ( "Hello, world" );
file = GetTempFileName ( "txt" );
text.Write ( file );
#endregion
#region upload
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
App.SetFileDialogResult ( true, file );
Click ( "#MenuUpload" );
#endregion
Pause ( __.Performance * 3 );
#region testFileContent
Set ( "#Message", "Tell me about the file attached" );
Click ( "#FormSend" );
#endregion
DeleteFiles ( file );
