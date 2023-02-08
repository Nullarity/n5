
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Project";
	p.Template = "Project";
	Print.Print ( p );
	
EndProcedure
