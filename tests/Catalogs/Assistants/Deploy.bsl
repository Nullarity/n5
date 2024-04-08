// Create and deploy an assistant

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A19E" );
this.Insert ( "ID", id );

#region createFile
text = new TextDocument ();
text.SetText ( "Hello, world" );
file = GetTempFileName ( "txt" );
text.Write ( file );
#endregion

#region createAndDeploy
Commando ( "e1cib/command/Catalog.Assistants.Create" );
Set ( "#Description", id );
Set ( "#Purpose", "Virtual Assistant" );
Set ( "#FullDescription", "You are good in math" );
Click ( "#CodeInterpreter" );
Click ( "#Retrieval" );
Set ( "#Model", "gpt-4-turbo-preview" );
Set ( "#Server", "Main" );
App.SetFileDialogResult ( true, file );
Click ( "#FilesUpload" );
Pause ( __.Performance * 2 );
Click ( "#FormWrite" );
Pause ( __.Performance * 3 );
CheckErrors ();
Click ( "#FormReDeploy" );
Pause ( __.Performance * 3 );
#endregion
