
&AtClient
Procedure CommandProcessing ( Email, CommandExecuteParameters )
	
	openList ( Email, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openList ( Email, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Email", Email );
	OpenForm ( "InformationRegister.ProjectsAndEmails.Form.Projects", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 
