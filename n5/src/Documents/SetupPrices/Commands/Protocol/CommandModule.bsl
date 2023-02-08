
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Protocol";
	p.Template = "Protocol";
	Print.Print ( p );
	
EndProcedure
