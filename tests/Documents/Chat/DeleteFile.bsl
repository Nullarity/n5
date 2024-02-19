// Check file deletion from AI storage

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A18W" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region DeleteFile
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Click ( "#MenuAttach" );
With ();
Put ( "#Addition1", id );
Pause ( 1 );
Get ( "#List" ).DeleteRow ();
With ();
Click ( "#Button0", DialogsTitle ); // yes
Pause ( 3 );
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
	
	#region createFile
	text = new TextDocument ();
	text.SetText ( "Hello, this is my ID: " + id );
	file = GetTempFileName ( id );
	text.Write ( file );
	#endregion
	#region upload
	Commando ( "e1cib/command/Document.Chat.Create" );
	Pick ( "#Assistant", "Thomas" );
	App.SetFileDialogResult ( true, file );
	Click ( "#MenuUpload" );
	Pause ( 10 );
	#endregion
	DeleteFiles ( file );
	CloseAll ();
	
	RegisterEnvironment ( id );

EndProcedure
