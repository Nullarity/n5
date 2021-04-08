
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "TimeEntry";
	p.Name = "TimeEntry";
	Print.Print ( p );
	
EndProcedure
