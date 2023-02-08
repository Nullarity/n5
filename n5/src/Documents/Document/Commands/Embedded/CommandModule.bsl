
&AtClient
Procedure CommandProcessing ( Object, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure ( "Object", Object ) );
	OpenForm ( "Document.Document.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
