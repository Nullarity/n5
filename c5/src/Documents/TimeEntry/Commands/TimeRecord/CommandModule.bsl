
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "TimeEntry";
	p.Template = "TimeEntry";
	Print.Print ( p );
	
EndProcedure
