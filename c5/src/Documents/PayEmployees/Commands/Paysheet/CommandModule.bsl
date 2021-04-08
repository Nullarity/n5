
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Paysheet";
	p.Name = "Paysheet";
	Print.Print ( p );	
	
EndProcedure
