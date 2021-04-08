
&AtClient
Procedure CommandProcessing ( Project, CommandExecuteParameters )
	
	openList ( Project, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openList ( Project, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Project", Project );
	OpenForm ( "InformationRegister.ProjectsAndEmails.Form.Emails", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 
