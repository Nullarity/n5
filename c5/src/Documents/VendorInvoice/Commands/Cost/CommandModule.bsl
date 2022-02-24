
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Cost";
	p.Template = "Cost";
	Print.Print ( p );
	
EndProcedure
