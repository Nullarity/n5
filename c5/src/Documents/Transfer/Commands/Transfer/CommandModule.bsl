
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Transfer";
	p.Name = "Transfer";
	Print.Print ( p );
	
EndProcedure