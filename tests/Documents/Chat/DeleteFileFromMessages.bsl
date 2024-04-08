// Check file deletion from message list

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A19D" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();
        
#region upload
Commando ( "e1cib/command/Document.Chat.Create" );
Pick ( "#Assistant", "Thomas" );
Click ( "#MenuAttachDocument" );
With ();
Set ( "#Addition3", this.Subject );
Click ( "#Choose" );
#endregion

Pause ( 2 );

#region delete
With ();
Click ( "#MessagesContextMenuDeleteFile" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Subject", "Document " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newDocument
	Commando("e1cib/command/Document.Document.Create");
	Set("#Subject", this.Subject );
	file = GetTempFileName("txt");
	doc = new TextDocument();
	doc.SetText ( "This is the test document " + id );
	doc.Write(file);
	App.SetFileDialogResult ( true, file );
	Activate("#Attachments");
	Click("#AttachmentsUpload");
	Pause(1);
	Click ( "#FormWrite" );
	DeleteFiles (file);
	#endregion

	RegisterEnvironment ( id );

EndProcedure