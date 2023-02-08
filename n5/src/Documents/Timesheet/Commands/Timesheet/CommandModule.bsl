
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Timesheet";
	p.Template = "Timesheet";
	Print.Print ( p );
	
EndProcedure
