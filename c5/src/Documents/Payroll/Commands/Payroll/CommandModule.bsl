
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Payroll";
	p.Name = "Payroll";
	Print.Print ( p );
	
EndProcedure
