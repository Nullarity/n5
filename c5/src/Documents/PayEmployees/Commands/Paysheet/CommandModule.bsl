
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Paysheet";
	p.Template = "Paysheet";
	Print.Print ( p );	
	
EndProcedure
