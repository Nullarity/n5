
&AtClient
Procedure CommandProcessing ( Email, CommandExecuteParameters )
	
	p = new Structure( "Email", Email );
	OpenForm ( "Catalog.Projects.ObjectForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window );
	
EndProcedure
