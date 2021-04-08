
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Timesheet";
	p.Name = "Timesheet";
	Print.Print ( p );
	
EndProcedure
