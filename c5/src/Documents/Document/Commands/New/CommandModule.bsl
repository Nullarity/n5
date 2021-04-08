
&AtClient
Procedure CommandProcessing ( Email, CommandExecuteParameters )
	
	newDocument ( Email );
	
EndProcedure

&AtClient
Procedure newDocument ( Email )
	
	p = new Structure ( "Command, Email", Enum.DocumentCommandsUploadEmail (), Email );	
	OpenForm ( "Document.Document.ObjectForm", p );
	
EndProcedure 