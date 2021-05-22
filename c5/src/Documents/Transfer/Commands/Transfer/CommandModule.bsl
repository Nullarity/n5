
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Transfer";
	p.Template = "Transfer";
	Print.Print ( p );
	
EndProcedure