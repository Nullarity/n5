// Check file uploading from the list of AI files

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A18X" );
this.Insert ( "ID", id );
        
#region createFile
text = new TextDocument ();
text.SetText ( "Hello, this is my ID: " + id );
file = GetTempFileName ( id );
text.Write ( file );
#endregion

#region upload
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Click ( "#MenuAttach" );
With ();
App.SetFileDialogResult ( true, file );
Click ( "#FormCreate" );
Pause ( 10 );
#endregion

DeleteFiles ( file );
